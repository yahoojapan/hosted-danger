module HostedDanger
  module Executor
    DANGERFILE_DEFAULT = File.expand_path("../../../../Dangerfile.default", __FILE__)
    TIMEOUT            = 1200

    def exec_danger(executable : Executable)
      env = {} of String => String
      action = executable[:action]
      event = executable[:event]
      html_url = executable[:html_url]
      pr_number = executable[:pr_number]
      sha = executable[:sha]
      base_branch = executable[:base_branch]
      raw_payload = executable[:raw_payload]

      git_host = git_host_from_html_url(html_url)
      org, repo = org_repo_from_html_url(html_url)
      access_token = access_token_from_git_host(git_host)

      repo_tag = "#{html_url} (event: #{event}) (pr: #{pr_number})"
      dir = "/tmp/#{Random::Secure.hex}"

      env["GIT_URL"] = html_url
      env["DANGER_ACTION"] = action
      env["DANGER_EVENT"] = event
      env["DANGER_PAYLOAD"] = raw_payload
      env["DANGER_GITHUB_HOST"] = git_host
      env["DANGER_GITHUB_API_BASE_URL"] = "http://localhost/proxy/#{symbol(git_host)}"
      env["DANGER_GITHUB_API_TOKEN"] = "Hi there! :)"
      env["ghprbPullId"] = "#{pr_number}"
      env["ghprbGhRepository"] = "#{org}/#{repo}"
      env.merge!(executable[:env])

      FileUtils.mkdir(dir)

      exec_cmd(repo_tag, "git init", dir, env)
      exec_cmd(repo_tag, "git config --local user.name ap-danger", dir, env)
      exec_cmd(repo_tag, "git config --local user.email hosted-danger-pj@ml.yahoo-corp.jp", dir, env)
      exec_cmd(repo_tag, "git remote add origin #{remote_from_html_url(html_url, access_token)}", dir, env)
      exec_cmd(repo_tag, "git fetch origin #{base_branch} --depth 50", dir, env)
      exec_cmd(repo_tag, "git fetch origin +refs/pull/#{pr_number}/head --depth 50", dir, env)
      exec_cmd(repo_tag, "git reset --hard FETCH_HEAD", dir, env)

      config_wrapper = ConfigWrapper.new(dir)

      dangerfile_path = "#{dir}/#{config_wrapper.dangerfile}"

      unless config_wrapper.events.includes?(event)
        return L.info "#{repo_tag} configuration doesn't include #{event} (#{config_wrapper.events})"
      end

      unless pull_request_open?(git_host, org, repo, pr_number, access_token)
        return L.info "#{repo_tag} the pull request has been closed."
      end

      L.info "#{repo_tag} execute: #{event} #{html_url} #{pr_number}"

      build_state(
        git_host,
        org,
        repo,
        sha,
        "I'm running!",
        access_token,
        State::PENDING,
      )

      #
      # Phase: パッケージ管理ツール
      # 注) npmとgemを両方使いたい、という場合がある
      #
      if config_wrapper.use_bundler?
        with_dragon_envs(env) do
          exec_cmd(repo_tag, "bundle_cache install #{dragon_params(env)}", dir, env, true)
        end
      end

      if config_wrapper.use_yarn?
        exec_cmd(repo_tag, "yarn install", dir, env)
      end

      if config_wrapper.use_npm?
        with_dragon_envs(env) do
          exec_cmd(repo_tag, "npm_cache install #{dragon_params(env)}", dir, env, true)
        end
      end

      #
      #  Phase: 実行
      #
      case config_wrapper.get_lang
      when "ruby"
        exec_ruby(config_wrapper, repo_tag, dangerfile_path, dir, env)
      when "js"
        exec_js(config_wrapper, repo_tag, dangerfile_path, dir, env)
      else
        raise "unknown lang: #{config_wrapper.get_lang}"
      end
    rescue e : Exception
      paster_url : String = if error_message = e.message
        upload_text(error_message)
      else
        "Sorry, failed to create logs..."
      end

      if git_host && org && repo && sha && access_token
        build_state(
          git_host.not_nil!, org.not_nil!, repo.not_nil!, sha.not_nil!,
          "Crashed during the execution. ERROR LOG ->",
          access_token.not_nil!,
          State::ERROR,
          paster_url,
        )
      end

      raise e
    ensure
      # jsではstatusがsuccessにならない問題がある(danger側の問題かこちら側の問題かは不明)
      # そこで、pendingのstatusを最後にsuccessにする必要がある
      if config_wrapper && config_wrapper.not_nil!.get_lang == "js" && git_host && org && repo && sha && access_token
        status = build_state_of(git_host.not_nil!, org.not_nil!, repo.not_nil!, sha.not_nil!, access_token.not_nil!)
        status.each do |state|
          if state["creator"]["login"].as_s == "ap-danger" && state["state"].as_s == "pending"
            build_state(
              git_host.not_nil!, org.not_nil!, repo.not_nil!, sha.not_nil!,
              "Success! yay!",
              access_token.not_nil!,
              State::SUCCESS,
            )
          end
        end
      end

      FileUtils.rm_rf(dir.not_nil!) if dir
    end

    private def exec_ruby(config_wrapper : ConfigWrapper, repo_tag : String, dangerfile_path : String, dir : String, env : Hash(String, String))
      exec_cmd(repo_tag, "cp #{DANGERFILE_DEFAULT} #{dangerfile_path}", dir, env) unless File.exists?(dangerfile_path)

      if config_wrapper.use_bundler?
        exec_cmd(repo_tag, "timeout #{TIMEOUT} bundle exec danger #{danger_params_ruby(dangerfile_path)}", dir, env)
      else
        exec_cmd(repo_tag, "timeout #{TIMEOUT} danger_ruby #{danger_params_ruby(dangerfile_path)}", dir, env)
      end
    end

    private def exec_js(config_wrapper : ConfigWrapper, repo_tag, dangerfile_path : String, dir : String, env : Hash(String, String))
      if config_wrapper.use_yarn?
        exec_cmd(repo_tag, "timeout #{TIMEOUT} yarn danger ci #{danger_params_js(dangerfile_path)}", dir, env)
      elsif config_wrapper.use_npm?
        exec_cmd(repo_tag, "timeout #{TIMEOUT} npm run danger -- ci #{danger_params_js(dangerfile_path)}", dir, env)
      else
        exec_cmd(repo_tag, "timeout #{TIMEOUT} danger ci #{danger_params_js(dangerfile_path)}", dir, env)
      end
    end

    private def exec_cmd(repo_tag : String, cmd : String, dir : String, env : Hash(String, String), hide_command : Bool = false)
      L.info "#{repo_tag} #{hide_command ? "**HIDDEN**" : cmd}"

      res = exec_cmd_internal(cmd, dir, env)

      L.info "#{repo_tag} ===> #{res[:stdout]}" if res[:stdout].size > 0

      unless res[:code] == 0
        _msg_command = "**COMMAND (#{res[:code]})**\n```\n#{hide_command ? "HIDDEN" : cmd}\n```"
        _msg_stdout = "**STDOUT**#{res[:code] == 124 ? " (**Build Timeout**)" : ""}\n```\n#{res[:stdout]}\n```"
        _msg_stderr = "**STDERR**\n```\n#{res[:stderr]}\n```"
        raise "#{repo_tag}\n\n#{_msg_command}\n\n#{_msg_stdout}\n\n#{_msg_stderr}"
      end
    end

    private def exec_cmd_internal(cmd : String, dir : String, env : Hash(String, String))
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      process = Process.run(cmd, env: env, shell: true, output: stdout, error: stderr, chdir: dir)

      stdout.close
      stderr.close

      {
        stdout: stdout.to_s,
        stderr: stderr.to_s,
        code:   process.exit_code,
      }
    end

    private def with_dragon_envs(env : Hash(String, String), &block)
      env["DRAGON_ACCESS_KEY"] = Envs.get("dragon_access_key")
      env["DRAGON_SECRET_ACCESS_KEY"] = Envs.get("dragon_secret_access_key")

      yield

      env.delete("DRAGON_ACCESS_KEY")
      env.delete("DRAGON_SECRET_ACCESS_KEY")
    end

    private def dragon_params(env : Hash(String, String)) : String
      [
        "--region kks",
        "--endpoint https://kks.dragon.storage-yahoo.jp",
        "--bucket hosted-danger-cache",
        "--access_key #{env["DRAGON_ACCESS_KEY"]}",
        "--secret_access_key #{env["DRAGON_SECRET_ACCESS_KEY"]}",
      ].join(" ")
    end

    private def danger_params_ruby(dangerfile_path : String) : String
      [
        "--dangerfile=#{dangerfile_path}",
        "--danger_id=#{DANGER_ID}",
      ].join(" ")
    end

    private def danger_params_js(dangerfile_path : String) : String
      [
        "--dangerfile #{dangerfile_path}",
        "--id #{DANGER_ID}",
      ].join(" ")
    end

    private def symbol(git_host : String) : String
      git_host.split(".")[0]
    end

    include Github
    include Paster
    include Parser
  end
end
