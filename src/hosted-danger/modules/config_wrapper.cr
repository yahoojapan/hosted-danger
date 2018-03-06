module HostedDanger
  class ConfigWrapper
    getter directory
    @config : Config?

    def initialize(@directory : String)
      @config = Config.parse("#{@directory}/danger.yaml")
    end

    def config_file_exists?
      @config.nil?
    end

    def dangerfile_exists?
      ruby_dangerfile_exists? || js_dangerfile_exists?
    end

    def ruby_dangerfile_exists?
      File.exists?("#{@directory}/Dangerfile.hosted")
    end

    def js_dangerfile_exists?
      File.exists?("#{@directory}/dangerfile.hosted.js") || File.exists?("#{@directory}/dangerfile.hosted.ts")
    end

    def get_lang : String
      if config = @config
        return config.lang.not_nil! if config.lang
      end

      return "ruby" if ruby_dangerfile_exists?
      return "js" if js_dangerfile_exists?

      "ruby" # by default
    end

    def dangerfile : String
      if config = @config
        return config.dangerfile.not_nil! if config.dangerfile
      end

      if get_lang == "js"
        return "dangerfile.hosted.js"
      end

      "Dangerfile.hosted"
    end

    def events : Array(String)
      if config = @config
        return config.events.not_nil! if config.events
      end

      [
        "pull_request",
        "pull_request_review",
        "pull_request_review_comment",
        "issue_comment",
        # https://ghe.corp.yahoo.co.jp/hosted-danger/hosted-danger/issues/99
        # "status",
      ]
    end

    def use_bundler? : Bool
      if config = @config
        return config.bundler.not_nil! if config.bundler
      end

      gemfile_exists? = File.exists?("#{@directory}/Gemfile")
      return false unless gemfile_exists?
      return true if File.read("#{@directory}/Gemfile") =~ /(gem\s*?'danger')/

      false
    end

    def use_yarn? : Bool
      if config = @config
        return config.yarn.not_nil! if config.yarn
      end

      yarn_lock_exists? = File.exists?("#{@directory}/yarn.lock")
      return false unless yarn_lock_exists?
      return true if File.read("#{@directory}/yarn.lock") =~ /danger@\^.*:/

      false
    end

    def use_npm? : Bool
      if config = @config
        return config.npm.not_nil! if config.npm
      end

      package_lock_exists? = File.exists?("#{@directory}/package-lock.json")
      return false unless package_lock_exists?
      return true if File.read("#{@directory}/package-lock.json") =~ /"danger":\s{/

      false
    end
  end
end
