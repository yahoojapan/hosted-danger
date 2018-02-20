require "random"
require "file_utils"

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

        if use_ruby?(directory)
          unless File.exists?("#{directory}/Dangerfile")
            L.warn "#{repo_tag} Dangerfile not found, use the default one"
            exec_cmd(repo_tag, "cp #{DANGERFILE_DEFAULT} #{directory}/Dangerfile", directory)
          end

          if use_bundler?(directory)
            exec_cmd(repo_tag, "bundle_cache install #{dragon_params}", directory, true)
            exec_cmd(repo_tag, "bundle exec danger #{danger_params_ruby}", directory)
          else
            exec_cmd(repo_tag, "danger_ruby #{danger_params_ruby}", directory)
          end
        else
          if use_yarn?(directory)
            exec_cmd(repo_tag, "yarn install", directory)
            exec_cmd(repo_tag, "yarn danger ci #{danger_params_js}", directory)
          elsif use_npm?(directory)
            # todo npm_cache
            exec_cmd(repo_tag, "npm install", directory, true)
            exec_cmd(repo_tag, "npm run danger ci #{danger_params_js}", directory)
          else
            exec_cmd(repo_tag, "danger ci #{danger_params_js}", directory)
          end
        end
      ensure
        FileUtils.rm_rf(directory)
      end
    end

    def use_ruby?(directory) : Bool
      ruby_dangerfile_exists? = File.exists?("#{directory}/Dangerfile")
      return true if ruby_dangerfile_exists?
      js_dangerfile_exists? = File.exists?("#{directory}/dangerfile.js") || File.exists?("#{directory}/dangerfile.ts")
      return false if js_dangerfile_exists?

      # use ruby by default
      true
    end

    def use_bundler?(directory) : Bool
      gemfile_exists? = File.exists?("#{directory}/Gemfile")
      return false unless gemfile_exists?
      return true if File.read("#{directory}/Gemfile") =~ /(gem\s*?'danger')/

      false
    end

    def use_yarn?(directory) : Bool
      yarn_lock_exists? = File.exists?("#{directory}/yarn.lock")
      return false unless yarn_lock_exists?
      return true if File.read("#{directory}/yarn.lock") =~ /danger@\^.*:/
      false
    end

    def use_npm?(directory) : Bool
      package_lock_exists? = File.exists?("#{directory}/package-lock.json")
      return false unless package_lock_exists?
      return true if File.read("#{directory}/package-lock.json") =~ /"danger":\s{/
      false
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

    private def danger_params_ruby : String
      [
        "--remove-previous-comments",
      ].join(" ")
    end

    private def danger_params_js : String
      [
        "",
      ].join(" ")
    end

    include Parser
  end
end
