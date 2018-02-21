module HostedDanger
  module Executor
    DANGERFILE_DEFAULT = File.expand_path("../../../../Dangerfile.default", __FILE__)

    def exec_danger(executable : Executable)
      action = executable[:action]
      event = executable[:event]
      html_url = executable[:html_url]
      pr_number = executable[:pr_number]
      raw_payload = executable[:raw_payload]

      git_host = git_host_from_html_url(html_url)
      org, repo = org_repo_from_html_url(html_url)
      access_token = access_token_from_git_host(git_host)

      repo_tag = "#{html_url} (event: #{event}) (pr: #{pr_number})"

      L.info "execute: #{event} #{html_url} #{pr_number}"

      directory = "/tmp/#{Random::Secure.hex}"

      ENV["GIT_URL"] = html_url
      ENV["DANGER_ACTION"] = action
      ENV["DANGER_EVENT"] = event
      ENV["DANGER_PAYLOAD"] = raw_payload
      ENV["DANGER_ID"] = "#{html_url}@#{pr_number}"
      ENV["DANGER_GITHUB_HOST"] = git_host
      ENV["DANGER_GITHUB_API_BASE_URL"] = "https://#{git_host}/api/v3"
      ENV["ghprbPullId"] = "#{pr_number}"
      ENV["ghprbGhRepository"] = "#{org}/#{repo}"

      if git_host == "ghe.corp.yahoo.co.jp"
        ENV["DANGER_GITHUB_API_TOKEN"] = ENV["DANGER_GITHUB_API_TOKEN_GHE"]
      else
        ENV["DANGER_GITHUB_API_TOKEN"] = ENV["DANGER_GITHUB_API_TOKEN_PARTNER"]
      end

      begin
        FileUtils.mkdir(directory)

        exec_cmd(repo_tag, "git init", directory)
        exec_cmd(repo_tag, "git remote add origin #{html_url}", directory)
        exec_cmd(repo_tag, "git fetch origin pull/#{pr_number}/head --depth 50", directory)
        exec_cmd(repo_tag, "git reset --hard FETCH_HEAD", directory)

        config_wrapper = ConfigWrapper.new(directory)
        dangerfile_path = "#{directory}/#{config_wrapper.dangerfile}"

        case config_wrapper.get_lang
        when "ruby"
          unless File.exists?(dangerfile_path)
            L.info "#{repo_tag} Dangerfile not found, use the default one"
            exec_cmd(repo_tag, "cp #{DANGERFILE_DEFAULT} #{dangerfile_path}", directory)
          end

          if config_wrapper.use_bundler?
            exec_cmd(repo_tag, "bundle_cache install #{dragon_params}", directory, true)
            exec_cmd(repo_tag, "bundle exec danger #{danger_params_ruby(dangerfile_path)}", directory)
          else
            exec_cmd(repo_tag, "danger_ruby #{danger_params_ruby(dangerfile_path)}", directory)
          end
        when "js"
          if config_wrapper.use_yarn?
            exec_cmd(repo_tag, "yarn install", directory)
            exec_cmd(repo_tag, "yarn danger ci #{danger_params_js(dangerfile_path)}", directory)
          elsif config_wrapper.use_npm?
            exec_cmd(repo_tag, "npm_cache install #{dragon_params}", directory, true)
            exec_cmd(repo_tag, "npm run danger ci #{danger_params_js(dangerfile_path)}", directory)
          else
            exec_cmd(repo_tag, "danger ci #{danger_params_js(dangerfile_path)}", directory)
          end
        else
          raise "unknown lang: #{config_wrapper.get_lang}"
        end
      ensure
        FileUtils.rm_rf(directory)
      end
    end

    def exec_cmd(repo_tag : String, cmd : String, dir : String, hide_command : Bool = false)
      L.info "#{repo_tag} #{hide_command ? "**HIDDEN**" : cmd}"

      res = exec_cmd_internal(cmd, dir)

      raise "#{repo_tag}\n```\n#{res[:stderr]}\n```" unless res[:status] == 0

      L.info "#{repo_tag} #{res[:stdout]}"
    end

    private def exec_cmd_internal(cmd : String, dir : String)
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      process = Process.run(cmd, shell: true, output: stdout, error: stderr, chdir: dir)

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
        "--bucket approduce-bundler-cache",
        "--access_key #{ENV["DRAGON_ACCESS_KEY"]}",
        "--secret_access_key #{ENV["DRAGON_SECRET_ACCESS_KEY"]}",
      ].join(" ")
    end

    private def danger_params_ruby(dangerfile_path : String) : String
      [
        "--dangerfile #{dangerfile_path}",
        "--remove-previous-comments",
      ].join(" ")
    end

    private def danger_params_js(dangerfile_path : String) : String
      [
        "--dangerfile #{dangerfile_path}",
      ].join(" ")
    end

    include Parser
  end
end
