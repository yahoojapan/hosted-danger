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

        Dir.cd(directory) do
          L.info "#{repo}: " + `git init`
          L.info "#{repo}: " + `git remote add origin #{html_url}`
          L.info "#{repo}: " + `git fetch origin pull/#{pr_number}/head --depth 50`
          L.info "#{repo}: " + `git reset --hard #{sha}`
          L.info "#{repo}: " + `danger`
        end
      ensure
        FileUtils.rm_rf(directory)
      end
    end
  end
end
