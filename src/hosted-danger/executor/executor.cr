module HostedDanger
  class Executor
    DANGERFILE_DEFAULT = File.expand_path("../../../../Dangerfile.default", __FILE__)
    TIMEOUT_DANGER     = 1200
    TIMEOUT_FETCH      =  600

    getter config_wrapper : ConfigWrapper

    #
    # === WARNING ===
    # `no_fetch` is not supported in OSS.
    # ===============
    #
    # Pre-fetched file list for no_fetch execution.
    #
    PREFETCH_FILES =
      [
        "Dangerfile.hosted.rb",
        "Dangerfile.hosted",
        "danger.yaml",
      ]

    #
    # Flag for no_fetch mode
    #
    @no_fetch_repo : Bool = true

    def initialize(@executable : Executable)
      @config_wrapper = ConfigWrapper.new(dir)
    end

    def exec_danger
      env["GIT_URL"] = html_url
      env["DANGER_ACTION"] = action
      env["DANGER_EVENT"] = event
      env["DANGER_PAYLOAD"] = raw_payload
      env["DANGER_GITHUB_HOST"] = git_host
      env["DANGER_GITHUB_API_BASE_URL"] = "http://localhost/proxy/#{symbol}"
      env["DANGER_GITHUB_API_TOKEN"] = "Hi there! :)"
      env["ghprbPullId"] = "#{pr_number}"
      env["ghprbGhRepository"] = "#{org}/#{repo}"

      #
      # -------------------------------------------
      # 1. Fetch danger.yaml and Dangerfile.hosted (.rb)
      # 2. Check the event
      # 3. Check the no_fetch mode
      # --------------------------------------------
      #
      # 1. Fetch danger.yaml and Dangerfile.hosted (.rb)
      #
      fetch_dangerfiles_repo

      #
      # load repo config
      #
      config_wrapper.load

      #
      # If there is no config, fetch org/danger additionally
      #
      unless config_wrapper.config_exists?
        fetch_dangerfiles_org

        if copy_config
          config_wrapper.load
          #
          # Put the no_fetch flag on
          #
          @no_fetch_repo = false
        end
      end

      L.info "no_fetch: #{config_wrapper.no_fetch_enable?}"

      #
      # 2. Check the event
      #
      unless config_wrapper.events.includes?(event)
        return L.info "#{repo_tag} configuration doesn't include #{event} (#{config_wrapper.events})"
      end

      #
      # The below case will not be triggered
      #
      # - Pull Request is closed
      #   - event is not "pull_request"
      #   - `exec_close: true` is not set on danger.yaml
      #
      unless pull_request_open?(git_host, org, repo, pr_number, access_token) ||
             (event == "pull_request" && config_wrapper.exec_close?)
        return L.info "#{repo_tag} the pull request has been closed."
      end

      #
      # 3. Check the not_fetch mode
      #
      if config_wrapper.no_fetch_enable?
        if @no_fetch_repo
          #
          # Execute no_fetch on repo config
          #
          fetch_files_repo
        else
          #
          # Execute no_fetch on org config
          #
          copy_config if git_fetch_org_config?
        end

        config_wrapper.load
      else
        #
        # Delete pre-fetched files
        #
        clean_prefetch_files
        #
        # Execute normally (without no_fetch danger)
        #
        git_fetch_repo

        config_wrapper.load

        unless config_wrapper.config_exists?
          if git_fetch_org_config? && copy_config
            config_wrapper.load
          end
        end
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
      # Phase: package management tools
      # Note that some user would like to use both of gem and npm. (e.g. for textlint)
      #
      if config_wrapper.use_bundler?
        exec_cmd("bundle install --path vendor/bundle", dir)
        env["BUNDLE_GEMFILE"] = config_wrapper.gemfile_path
      end

      if config_wrapper.use_yarn?
        exec_cmd("yarn install", dir)
      elsif config_wrapper.use_npm?
        exec_cmd("npm install", dir)
      end

      #
      #  Phase: Execution
      #
      case config_wrapper.get_lang
      when "ruby"
        exec_ruby
      when "js"
        exec_js
      else
        raise "unknown lang: #{config_wrapper.get_lang}"
      end

      clean_comments
    rescue e : Exception
      paster_url : String = if error_message = e.message
                              upload_text(error_message)
                            else
                              "Sorry, failed to create logs..."
                            end

      build_state(git_host, org, repo, sha, "Crashed during the execution. ERROR LOG ->", access_token, State::ERROR, paster_url)

      raise e
    ensure
      # dangerjs doesn't put success status on CI statuses.
      # So put success status on it manually.
      if config_wrapper.get_lang == "js"
        status = build_state_of(git_host, org, repo, sha, access_token)
        status.as_a.each do |state|
          if state["creator"]["login"].as_s == app_user && state["state"].as_s == "pending"
            build_state(git_host, org, repo, sha, "Success! yay!", access_token, State::SUCCESS)
          end
        end
      end

      FileUtils.rm_rf(org_dir)
      FileUtils.rm_rf(dir)
    end

    def exec_ruby
      exec_cmd("cp #{DANGERFILE_DEFAULT} #{dangerfile_path}", dir) unless File.exists?(dangerfile_path)

      danger_bin = if config_wrapper.use_bundler?
                     if config_wrapper.no_fetch_enable?
                       "bundle exec no_fetch_danger"
                     else
                       "bundle exec danger"
                     end
                   else
                     if config_wrapper.no_fetch_enable?
                       "no_fetch_danger"
                     else
                       "danger_ruby"
                     end
                   end

      exec_cmd("timeout #{TIMEOUT_DANGER} #{danger_bin} #{danger_params_ruby}", dir)
    end

    def exec_js
      danger_bin = if config_wrapper.use_yarn? || config_wrapper.use_npm?
                     "#{config_wrapper.directory}/node_modules/.bin/danger"
                   else
                     "danger"
                   end

      exec_cmd("timeout #{TIMEOUT_DANGER} #{danger_bin} ci #{danger_params_js}", dir)
    end

    def exec_cmd(cmd : String, dir : String)
      L.info "#{repo_tag} #{hidden(cmd)}"

      res = exec_cmd_internal(cmd, dir)

      L.info "#{repo_tag} ===> #{hidden(res[:stdout])}" if res[:stdout].size > 0

      unless res[:code] == 0
        _msg_command = "**COMMAND (#{res[:code]})**\n```\n#{hidden(cmd)}\n```"
        _msg_stdout = "**STDOUT**#{res[:code] == 124 ? " (**Build Timeout**)" : ""}\n```\n#{hidden(res[:stdout])}\n```"
        _msg_stderr = "**STDERR**\n```\n#{hidden(res[:stderr])}\n```"
        raise "#{repo_tag}\n\n#{_msg_command}\n\n#{_msg_stdout}\n\n#{_msg_stderr}"
      end
    end

    def exec_cmd_internal(cmd : String, dir : String)
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

    def clean_comments
      comments = issue_comments(git_host, org, repo, pr_number, access_token)

      delete_comments = comments.as_a
                        .select { |comment| app_user == comment["user"]["login"].as_s }
                        .select { |comment| comment["body"].as_s.includes?("generated_by_hosted-danger") }

      return if delete_comments.size <= 1

      delete_comments[0..-2].each do |comment|
        L.info "#{repo_tag} delete comment: #{comment["id"]}"
        delete_comment(git_host, org, repo, comment["id"].as_i, access_token)
      end
    end

    def copy_config : Bool
      src_files = Dir.glob("#{org_dir}/*").join(" ")
      return false if src_files.size == 0
      exec_cmd("cp -rf #{src_files} #{dir}", org_dir)
      true
    end

    def danger_params_ruby : String
      [
        "--dangerfile=#{dangerfile_path}",
        "--danger_id=#{DANGER_ID}",
      ].join(" ")
    end

    def danger_params_js : String
      [
        "--dangerfile #{dangerfile_path}",
        "--id #{DANGER_ID}",
      ].join(" ")
    end

    def env
      @executable[:env]
    end

    def action
      @executable[:action]
    end

    def event
      @executable[:event]
    end

    def html_url
      @executable[:html_url]
    end

    def pr_number
      @executable[:pr_number]
    end

    def sha
      @executable[:sha]
    end

    def head_label
      @executable[:head_label]
    end

    def base_label
      @executable[:base_label]
    end

    def base_branch
      @executable[:base_label].includes?(":") ? @executable[:base_label].split(":", 2)[1] : @executable[:base_label]
    end

    def raw_payload
      @executable[:raw_payload]
    end

    def git_host
      git_host_from_html_url(html_url)
    end

    def org
      org_repo_from_html_url(html_url)[0]
    end

    def repo
      org_repo_from_html_url(html_url)[1]
    end

    def access_token
      access_token_from_git_host(git_host)
    end

    def repo_tag
      "#{html_url}/pull/#{pr_number} (event: #{event})"
    end

    def app_user : String
      ServerConfig.app_user(git_host)
    end

    def org_dir : String
      @org_dir ||= "/tmp/#{Random::Secure.hex}"
      Dir.mkdir(@org_dir.not_nil!) unless Dir.exists?(@org_dir.not_nil!)
      @org_dir.not_nil!
    end

    def dir : String
      @dir ||= "/tmp/#{Random::Secure.hex}"
      Dir.mkdir(@dir.not_nil!) unless Dir.exists?(@dir.not_nil!)
      @dir.not_nil!
    end

    def dangerfile_path
      config_wrapper.dangerfile_path
    end

    def symbol : String
      git_host.split(".")[0]
    end

    def hidden(text : String) : String
      result = text.gsub(access_token, "***")
      result
    end

    def fetch_file_repo(file : String) : String?
      fetch_file(git_host, org, repo, sha, file, access_token, dir)
    end

    def fetch_file_org(file : String) : String?
      fetch_file(git_host, org, "danger", "master", file, access_token, org_dir)
    end

    def fetch_files_repo
      config_wrapper.no_fetch_files.each do |file|
        #
        # Except pre-fetched files
        #
        next if PREFETCH_FILES.includes?(file)
        fetch_file_repo(file)
      end
    end

    def fetch_dangerfiles_repo
      PREFETCH_FILES.each do |file|
        fetch_file_repo(file)
      end
    end

    def fetch_dangerfiles_org
      PREFETCH_FILES.each do |file|
        fetch_file_org(file)
      end
    end

    def clean_prefetch_files
      PREFETCH_FILES.each do |file|
        file_path_dir = "#{dir}/#{file}"
        file_path_org_dir = "#{org_dir}/#{file}"
        File.delete(file_path_dir) if File.exists?(file_path_dir)
        File.delete(file_path_org_dir) if File.exists?(file_path_org_dir)
      end
    end

    def git_fetch_repo
      commits = compare(git_host, org, repo, access_token, base_label, head_label)

      ahead_by = commits["ahead_by"].as_i
      behind_by = commits["behind_by"].as_i

      exec_cmd("git init", dir)
      exec_cmd("git config --local user.name #{app_user}", dir)
      exec_cmd("git config --local user.email hosted-danger-pj@ml.yahoo-corp.jp", dir)
      exec_cmd("git config --local http.postBuffer 1048576000", dir)
      exec_cmd("git remote add origin #{remote_from_html_url(html_url, access_token)}", dir)
      exec_cmd("timeout #{TIMEOUT_FETCH} git fetch origin #{base_branch} --depth #{behind_by + 1}", dir)
      exec_cmd("timeout #{TIMEOUT_FETCH} git fetch origin +refs/pull/#{pr_number}/head --depth #{ahead_by + 1}", dir)
      exec_cmd("git reset --hard FETCH_HEAD", dir)
    end

    def git_fetch_org_config? : Bool
      repo = "danger"

      exec_cmd("git init", org_dir)
      exec_cmd("git config --local user.name #{app_user}", org_dir)
      exec_cmd("git config --local user.email hosted-danger-pj@ml.yahoo-corp.jp", org_dir)
      exec_cmd("git remote add origin https://#{app_user}:#{access_token}@#{git_host}/#{org}/#{repo}.git", org_dir)
      exec_cmd("git fetch --depth 1", org_dir)
      exec_cmd("git reset --hard origin/master", org_dir)
      exec_cmd("rm -rf .git* README.md", org_dir)

      true
    rescue
      false
    end

    include Github
    include Paster
    include Parser
  end
end
