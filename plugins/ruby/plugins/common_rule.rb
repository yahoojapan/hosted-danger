module Danger
  # 全プロジェクトで使用可能な共通ルール
  #
  # @example
  #
  #
  #   common_rule.check
  #
  #
  class DangerCommonRule < Plugin
    def check(big_pr_lines: 1000)
      ############################################################
      ## Common
      ############################################################


      track_files = []
      track_file_lines = 0

      is_wip = review.wip?
      is_test = github.pr_title.downcase.include?("[test]")
      is_dnm = review.dnm?

      warn "Work In Progress. :construction:" if is_wip
      warn "This is a test. :dash:" if is_test
      warn "At the authors request please DO NOT MERGE this PR. :no_good_woman: <!-- #reviewable -->" if is_dnm

      # GitHubの処理のタイミングによってmergeableが一瞬だけ false になっていることがあるのでコメントアウト
      # warn "Not mergeable! :no_entry:" unless github.pr_json["mergeable"]

      # タイトルのみで説明が空のプルリクもよくあるので、共通ルールからは外す
      # warn "Please provide a summary in the Pull Request description. :writing_hand:" if github.pr_body.strip.empty?

      # diffでエラーが多発するためコメントアウト
      # if defined? Danger::DangerTodoist
      #   todoist.warn_for_todos
      # else
      #   message "`common_rule` を使用する場合は `Gemfile` に [danger-todoist](https://github.com/hanneskaeufler/danger-todoist) プラグインも追加してください。"
      # end

      ############################################################
      ## Danger
      ############################################################

      track_files += %w(Dangerfile dangerfile.js dangerfile.ts)
      track_files += %w(Dangerfile.hosted Dangerfile.hosted.rb dangerfile.hosted.js dangerfile.hosted.ts)
      track_files += %w(danger.yaml)

      ############################################################
      ## Git
      ############################################################

      track_files += %w(.gitignore .gitattributes .gitmodules)

      ############################################################
      ## GitHub
      ############################################################

      track_files += %w(PULL_REQUEST_TEMPLATE.md ISSUE_TEMPLATE.md CONTRIBUTING.md)

      ############################################################
      ## JavaScript
      ############################################################

      track_files += %w(package.json package-lock.json .npmrc npm-shrinkwrap.json yarn.lock .yarnrc)
      track_files += %w(.flowconfig )

      # babel
      track_files += %w(.babelrc)
      track_files << /^.babelrc.*/

      # eslint
      track_files << /^.eslintrc.*/
      track_files += %w(.eslintignore)

      # stylelint
      track_files += %w(.stylelintrc stylelint.config.js .stylelintignore)

      # PostCSS
      track_files += %w(.postcssrc.js)

      # TypeScript
      track_files += %w(tsconfig.json)

      # tslint
      track_files += %w(tslint.json)

      # nuxt
      track_files += %w(nuxt.config.js)

      # jest
      track_files += %w(jest.config.js)

      # karma
      track_files += %w(karma.conf.js)

      # webpack
      track_files += %w(webpack.config.js)

      # rollup
      track_files += %w(rollup.config.js)

      # Backpack
      track_files += %w(backpack.config.js)

      # browserlist ( https://github.com/ai/browserslist )
      track_files += %w(.browserslistrc)

      # lerna
      track_files += %w(lerna.json)

      # gulp
      track_files += %w(gulpfile.js gulpfile.babel.js)

      # reg-suit
      track_files += %w(regconfig.json)

      ############################################################
      ## Ruby
      ############################################################

      track_files += %w(Gemfile Gemfile.lock)
      track_files += %w(Rakefile .rubocop.yml)
      track_files += %w(.ruby-version)
      track_files << /\.gemspec$/

      ############################################################
      ## PHP
      ############################################################

      track_files += %w(composer.json composer.lock)
      track_files += %w(.php-version)

      ############################################################
      ## GO
      ############################################################

      track_files += %w(.go-version)

      # dep
      track_files += %w(Gopkg.toml Gopkg.lock)

      # glide
      track_files += %w(glide.yaml glide.lock)

      ############################################################
      ## Crystal
      ############################################################

      track_files += %w(shard.yml shard.lock)
      track_files += %w(.crystal-version)

      ############################################################
      ## Rust
      ############################################################

      track_files += %w(Cargo.toml Cargo.lock)
      track_files += %w(.rust-version)

      ############################################################
      ## Python
      ############################################################

      track_files += %w(.venv Pipfile Pipfile.lock)
      track_files += %w(.python-version)

      ############################################################
      ## Perl
      ############################################################

      track_files += %w(.perl-version)

      ############################################################
      ## Java
      ############################################################

      track_files += %w(.java-version)
      track_files += %w(pom.xml)

      ############################################################
      ## iOS / Swift
      ############################################################

      track_files += %w(project.pbxproj)
      track_files += %w(Cartfile Cartfile.resolved Cartfile.private)
      track_files += %w(Podfile Podfile.lock)
      track_files += %w(.swiftlint.yml)
      track_files << /\.podspec$/
      track_files += %w(Fastfile Snapfile Deliverfile Appfile Scanfile Gymfile Matchfile)
      track_files += %w(Package.swift Package.resolved) # SwiftPM

      ############################################################
      ## Android
      ############################################################

      track_files += %w(build.gradle gradle.properties gradlew gradlew.bat settings.gradle)

      ############################################################
      ## Textlint
      ############################################################

      track_files += %w(.textlintrc)

      ############################################################
      ## EditorConfig
      ############################################################

      track_files += %w(.editorconfig)

      ############################################################
      ## Makefile, etc ...
      ############################################################

      track_files += %w(Makefile)

      ############################################################
      ## Docker
      ############################################################

      track_files += %w(Dockerfile)

      ############################################################
      ## Screwdriver
      ############################################################

      track_files += %w(screwdriver.yaml)

      ############################################################
      ## Concourse
      ############################################################

      track_files += %w()

      ############################################################
      ## PCF
      ############################################################

      track_files += %w(manifest.yml .cfignore)

      ############################################################

      begin
        track_files.each do |track_file|
          next unless track_file.is_a?(String)
          next unless git.info_for_file(track_file)
          track_file_lines += git.info_for_file(track_file)[:insertions]
          track_file_lines += git.info_for_file(track_file)[:deletions]
        end

        message "Big PR (> #{big_pr_lines} lines), try to keep changes smaller if you can. :arrow_heading_down:" if git.lines_of_code - track_file_lines > big_pr_lines

        (git.modified_files || []).each do |path|
          track_files.each do |pattern|
            file_name = File.basename(path)
            matched = pattern.kind_of?(String) ? file_name == pattern : file_name.match(pattern)
            message "`#{path}` has changed." if matched
          end
        end
      rescue => e
        message "common_rule.checkの適応に失敗しました。 ([該当するエラー](https://pages.ghe.corp.yahoo.co.jp/hosted-danger/docs/trouble.html#utf8))"
      end
    end
  end
end
