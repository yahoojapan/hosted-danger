module HostedDanger
  class ConfigWrapper
    getter directory
    @config : Config?

    def initialize(@directory : String)
    end

    def load
      @config = Config.create_from("#{@directory}/danger.yaml")
    end

    def config_exists?
      config_file_exists? || dangerfile_exists?
    end

    def config_file_exists?
      !@config.nil?
    end

    def dangerfile_exists?
      ruby_dangerfile_exists? || js_dangerfile_exists?
    end

    def ruby_dangerfile_exists?
      File.exists?("#{@directory}/Dangerfile.hosted") || File.exists?("#{@directory}/Dangerfile.hosted.rb")
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

    def dangerfile_path : String
      "#{@directory}/#{dangerfile}"
    end

    def dangerfile : String
      if config = @config
        return config.dangerfile.not_nil! if config.dangerfile
      end

      # ここにくるのは
      # 1. 設定でjsとした場合
      # 2. ファイルの存在で、システムがjsと判断した場合
      if get_lang == "js"
        if File.exists?("#{@directory}/dangerfile.hosted.js")
          return "dangerfile.hosted.js"
        elsif File.exists?("#{@directory}/dangerfile.hosted.ts")
          return "dangerfile.hosted.ts"
        else
          # 設定でjsにしているのに該当するファイルがない場合にここに来る
          raise "dangerfile.hosted.[js|ts] not found"
        end
      end

      # ここにくるのは
      # 1. 設定でrubyとした場合
      # 2. ファイルの存在で、システムがrubyと判断した場合
      # 3. 設定もファイルも存在しておらず、デフォルトのDangerfile.hostedを使用する場合
      return "Dangerfile.hosted.rb" if File.exists?("#{@directory}/Dangerfile.hosted.rb")

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
        "issues",
        "build_periodcally",
        "status",
      ]
    end

    def use_bundler? : Bool
      if config = @config
        return config.bundler.not_nil! if config.bundler
      end

      gemfile_exists? = File.exists?("#{@directory}/Gemfile")
      return false unless gemfile_exists?
      return true if File.read("#{@directory}/Gemfile") =~ /(gem\s*?'danger')/
      return true if File.read("#{@directory}/Gemfile") =~ /(gem\s*?'no_fetch_danger')/

      false
    end

    def gemfile_path
      "#{@directory}/Gemfile"
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

    def exec_close? : Bool
      if config = @config
        return config.exec_close.not_nil! if config.exec_close
      end

      false
    end

    def no_fetch_enable? : Bool
      return false unless config = @config
      return false unless no_fetch = config.no_fetch
      return false unless enable = no_fetch.enable

      enable
    end

    #
    # `no_fetch.enable: true`時にデフォルトで fetch するファイル
    # fetchするファイルを変更する場合は、`no_fetch.files`を使う
    #
    DEFAULT_FETCH_FILES =
      [
        "Dangerfile.hosted",
        "Dangerfile.hosted.rb",
        "danger.yaml",
        "Gemfile",
        "Gemfile.lock",
      ]

    def no_fetch_files : Array(String)
      return DEFAULT_FETCH_FILES unless config = @config
      return DEFAULT_FETCH_FILES unless no_fetch = config.no_fetch
      return DEFAULT_FETCH_FILES unless files = no_fetch.files

      DEFAULT_FETCH_FILES.concat(files).uniq
    end
  end
end
