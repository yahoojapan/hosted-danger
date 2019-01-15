require "danger/plugin_support/plugin"
require "danger/core_ext/file_list"

# Danger
module Danger
  #
  # no-fetch GitPlugin
  #
  class DangerfileGitPlugin < Plugin
    # no-fetch: supported (not changed)
    def self.instance_name
      "git"
    end

    # no-fetch: Use Github as a request_source. Otherwise it raises.
    def initialize(dangerfile)
      super(dangerfile)
      raise unless dangerfile.env.request_source.class == Danger::RequestSources::GitHub

      @github = dangerfile.env.request_source
    end

    # no-fetch
    def added_files
      compares.select { |file| file.type == "new" }.map(&:path)
    end

    # no-fetch
    def deleted_files
      compares.select { |file| file.type == "deleted" }.map(&:path)
    end

    # no-fetch
    def modified_files
      compares.select { |file| file.type == "modified" }.map(&:path)
    end

    # no-fetch
    def renamed_files
      compares.select { |file| file.type == "renamed" }.map { |file| { before: file.before, after: file.after } }
    end

    # no-fetch: not supported
    def diff
      raise "GitPlugin#diff is not supported for no_fetch_danger"
    end

    # no-fetch
    def lines_of_code
      compares.reduce(0) { |s, f| s + f.changes }
    end

    # no-fetch
    def deletions
      compares.reduce(0) { |s, f| s + f.deletions }
    end

    # no-fetch
    def insertions
      compares.reduce(0) { |s, f| s + f.additions }
    end

    # no-fetch: not supported
    def commits
      raise "GitPlugin#commits is not supported for no_fetch_danger"
    end

    # no-fetch
    def diff_for_file(file)
      compares.find { |f| file == f.path }
    end

    # no-fetch
    def info_for_file(file)
      return nil unless diff_file = compares.find { |f| file == f.path }
      diff_file.to_h
    end

    def base_repo
      @github.pr_json["base"]["repo"]["full_name"]
    end

    def base_sha
      @github.pr_json["base"]["sha"]
    end

    def head_sha
      @github.pr_json["head"]["sha"]
    end

    def compare
      @compare ||= @github.client.compare(base_repo, base_sha, head_sha)
    end

    def compares
      @compares ||= compare[:files].map do |file|
        diff_file = DiffFile.new
        diff_file.patch = file[:patch] || ""
        diff_file.path = file[:filename]
        diff_file.type = type_of(file[:status])
        diff_file.additions = file[:additions]
        diff_file.deletions = file[:deletions]
        diff_file.changes = file[:changes]

        if file[:status] == "renamed"
          diff_file.before = file[:previous_filename]
          diff_file.after = file[:filename]
        end

        diff_file
      end
    end

    #
    # compatible with https://github.com/ruby-git/ruby-git/blob/master/lib/git/diff.rb#L72 (not fully)
    #
    class DiffFile
      attr_accessor :patch, :path, :type, :before, :after, :additions, :deletions, :changes
      #
      # :type is one of new, deleted, modified
      # :before and :after are used in renamed files
      #
      def to_h
        {
          insertions: @additions,
          deletions: @deletions,
          before: @before,
          after: @after,
        }
      end
    end

    #
    # To keep a compatibility with ruby-gith/ruby-git
    #
    def type_of(status)
      case status
      when "added"
        "new"
      when "removed"
        "deleted"
      when "modified"
        "modified"
      when "renamed"
        "renamed"
      else
        "unknown"
      end
    end
  end
end
