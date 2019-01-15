module Danger
  class DangerTestCode < Plugin
    DEFAULT_MESSAGE = "Consider update/add tests if changes are non-trivial. :information_desk_person:"

    def check(source: %r{^src/}, test: %r{^(spec|test)/}, message: DEFAULT_MESSAGE, sticky: false)
      is_source_changed = !(git.modified_files + git.added_files).grep(source).empty?
      is_test_changed = !(git.modified_files + git.added_files).grep(test).empty?

      if is_source_changed && !is_test_changed && !trivial?
        warn(message, sticky: sticky)
      end
    end

    private

    def trivial?
      (github.pr_title + github.pr_body).include?("#trivial")
    end
  end
end
