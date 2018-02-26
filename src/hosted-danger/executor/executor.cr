module HostedDanger
  module Executor
    DANGERFILE_DEFAULT = File.expand_path("../../../../Dangerfile.default", __FILE__)

    def exec_danger(executable : Executable)
      env = {} of String => String
      action = executable[:action]
      event = executable[:event]
      html_url = executable[:html_url]
      pr_number = executable[:pr_number]
      sha = executable[:sha]
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
      env["DANGER_GITHUB_API_BASE_URL"] = "https://#{git_host}/api/v3"
      env["ghprbPullId"] = "#{pr_number}"
      env["ghprbGhRepository"] = "#{org}/#{repo}"
      env.merge!(executable[:env])

      if git_host == "ghe.corp.yahoo.co.jp"
        env["DANGER_GITHUB_API_TOKEN"] = ENV["DANGER_GITHUB_API_TOKEN_GHE"]
      else
        env["DANGER_GITHUB_API_TOKEN"] = ENV["DANGER_GITHUB_API_TOKEN_PARTNER"]
      end

      FileUtils.mkdir(dir)

      exec_cmd(repo_tag, "git init", dir, env)
      exec_cmd(repo_tag, "git config --local user.name ap-danger", dir, env)
      exec_cmd(repo_tag, "git config --local user.email hosted-danger-pj@ml.yahoo-corp.jp", dir, env)
      exec_cmd(repo_tag, "git remote add origin #{remote_from_html_url(html_url, access_token)}", dir, env)
      exec_cmd(repo_tag, "git fetch origin pull/#{pr_number}/head --depth 50", dir, env)
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

      case config_wrapper.get_lang
      when "ruby"
        unless File.exists?(dangerfile_path)
          L.info "#{repo_tag} Dangerfile.hosted not found, use the default one"
          exec_cmd(repo_tag, "cp #{DANGERFILE_DEFAULT} #{dangerfile_path}", dir, env)
        end

        if config_wrapper.use_bundler?
          exec_cmd(repo_tag, "bundle_cache install #{dragon_params}", dir, env, true)
          exec_cmd(repo_tag, "bundle exec danger #{danger_params_ruby(dangerfile_path)}", dir, env)
        else
          exec_cmd(repo_tag, "danger_ruby #{danger_params_ruby(dangerfile_path)}", dir, env)
        end
      when "js"
        if config_wrapper.use_yarn?
          exec_cmd(repo_tag, "yarn install", dir, env)
          exec_cmd(repo_tag, "yarn danger ci #{danger_params_js(dangerfile_path)}", dir, env)
        elsif config_wrapper.use_npm?
          exec_cmd(repo_tag, "npm_cache install #{dragon_params}", dir, env, true)
          exec_cmd(repo_tag, "npm run danger -- ci #{danger_params_js(dangerfile_path)}", dir, env)
        else
          exec_cmd(repo_tag, "danger ci #{danger_params_js(dangerfile_path)}", dir, env)
        end
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
      FileUtils.rm_rf(dir.not_nil!) if dir

      # jsではstatusがsuccessにならない問題がある(danger側の問題かこちら側の問題かは不明)
      # そこで、pendingのstatusを最後にsuccessにする必要がある
      if config_wrapper && config_wrapper.not_nil!.get_lang == "js" && git_host && org && repo && sha && access_token
        puts "come here"
        status = build_state_of(git_host.not_nil!, org.not_nil!, repo.not_nil!, sha.not_nil!,access_token.not_nil!)
        puts status

        status.each do |state|
          puts state
          if state["creator"]["login"].as_s == "ap-danger" && state["state"].as_s == "pending"
            build_state(
              git_host.not_nil!, org.not_nil!, repo.not_nil!, sha.not_nil!,
              "Success! :tada:",
              access_token.not_nil!,
              State::SUCCESS,
            )
          end
        end
      end
    end

    def exec_cmd(repo_tag : String, cmd : String, dir : String, env : Hash(String, String), hide_command : Bool = false)
      L.info "#{repo_tag} #{hide_command ? "**HIDDEN**" : cmd}"

      res = exec_cmd_internal(cmd, dir, env)

      L.info "#{repo_tag} #{res[:stdout]}"

      _msg_command = "**COMMAND**```\n#{hide_command ? "HIDDEN" : cmd}\n```"
      _msg_stdout = "**STDOUT**\n```\n#{res[:stdout]}\n```"
      _msg_stderr = "**STDERR**\n```\n#{res[:stderr]}\n```"

      raise "#{repo_tag}\n\n#{_msg_command}\n\n#{_msg_stdout}\n\n#{_msg_stderr}" unless res[:status] == 0
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
        status: process.exit_status,
      }
    end

    private def dragon_params : String
      [
        "--region kks",
        "--endpoint https://kks.dragon.storage-yahoo.jp",
        "--bucket hosted-danger-cache",
        "--access_key #{ENV["DRAGON_ACCESS_KEY"]}",
        "--secret_access_key #{ENV["DRAGON_SECRET_ACCESS_KEY"]}",
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

    include Github
    include Paster
    include Parser
  end
end
