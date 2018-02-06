require "random"
require "file_utils"

module HostedDanger
  module Executor

    def exec(pr_payload)
      if pr_payload["sender"]["login"].to_s == "ap-approduce"
        return L.info "Skip, since it's coming from ap-approduce"
      end

      sha = pr_payload["pull_request"]["head"]["sha"].as_s
      html_url = pr_payload["pull_request"]["head"]["repo"]["html_url"].as_s
      pr_number = pr_payload["number"].as_i
      repo = "#{html_url}##{sha}(#{pr_number})"

      L.info "Execute for #{repo}"

      directory = "/tmp/#{Random::Secure.hex}"

      ENV["GIT_URL"] = html_url
      ENV["DANGER_ID"] = "#{html_url}@#{pr_number}"
      ENV["DANGER_GITHUB_HOST"] = "ghe.corp.yahoo.co.jp"
      ENV["DANGER_GITHUB_API_BASE_URL"] = "https://ghe.corp.yahoo.co.jp/api/v3"
      ENV["ghprbPullId"] = "#{pr_number}"

      begin
        FileUtils.mkdir(directory)

        exec_cmd(repo, "git init", directory)
        exec_cmd(repo, "git remote add origin #{html_url}", directory)
        exec_cmd(repo, "git fetch origin pull/#{pr_number}/head --depth 50", directory)
        exec_cmd(repo, "git reset --hard #{sha}", directory)

        if File.exists?("#{directory}/Gemfile")
          exec_cmd(repo, "bundle install --path #{directory}/vendor/bundle", directory)
          exec_cmd(repo, "bundle exec danger", directory)
        else
          exec_cmd(repo, "danger", directory)
        end
      ensure
        FileUtils.rm_rf(directory)
      end
    end

    def exec_cmd(repo : String, cmd : String, dir : String? = nil)
      L.info "#{repo}: #{cmd}"

      res = exec_cmd_internal(cmd, dir)

      unless res[:status] == 0
        L.error("#{repo}: \n```\n#{res[:stderr]}\n```")
        raise res[:stderr]
      end

      L.info "#{repo}: #{res[:stdout]}"
    end

    private def exec_cmd_internal(cmd : String, dir : String? = nil)
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
  end
end
