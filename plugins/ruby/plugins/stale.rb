require "date"
module Danger
  #
  # Staleの状態を保持する内部インスタンス
  #
  class StaleState
    @@commented = false

    def initialize(dangerfile)
      @dangerfile = dangerfile
      @exec_flag = !closed?

      unless @@commented
        @dangerfile.message ":alarm_clock: Stale 機能が有効です!"
        @@commented = true
      end
    end

    def exec(&blocked)
      yield
    end

    def exec_if(&blocked)
      return self unless @flag
      @exec_flag = !!yield

      self
    end

    def close
      return self unless enabled?
      github.api.close_pull_request(repo, number)
      self
    end

    def comment(comment = "このPRは一定期間放置されています")
      return self unless enabled?

      comment = comment[:comment] if comment.is_a?(Hash)

      github.api.add_comment(repo, number, comment)
      self
    end

    def comment_with_mentions(comment: "このPRは一定期間放置されています", mentions: [:all])
      return self unless enabled?
      mentions = mentions
                  .map {|s| participants(s) }
                  .flatten
                  .compact
                  .uniq
                  .map {|x| "@#{x}" }
                  .join(' ')
      comment = mentions + ' ' + comment
      github.api.add_comment(repo, number, comment)
      self
    end

    def mym(comment: pr_url + " このPRは一定期間放置されています", token: nil, room: nil)
      return self unless enabled?
      dangerfile.mym.post(comment, token, room)
      self
    end

    def mym_with_mentions(comment: pr_url + " このPRは一定期間放置されています", token: nil, room: nil, mentions: [:all])
      return self unless enabled?
      mentions = mentions
                   .map {|s| participants(s) }
                   .flatten
                   .compact
                   .uniq
                   .map {|x| "@#{x}" }
                   .join(' ')
      comment = mentions + ' ' + comment
      dangerfile.mym.post(comment, token, room)
      self
    end

    def label(label)
      # after_*を満たしていない時はreturn
      return self unless @flag
      return self unless @exec_flag
      # labelがnilの時はreturn
      return self unless label

      if github.pr_labels.none? {|l| l == label }
        github.api.add_labels_to_an_issue(repo, number, [ label ])
      else
        # すでにlabelが付与されているので、実行はスキップする
        @skip = true
      end

      self
    end

    def enabled?
      return false unless @flag
      return false if @skip
      return false unless @exec_flag

      true
    end

    def span_secs(secs)
      id = "secs_#{secs}"

      if secs.nil? || (now - span_exected_at(id)) < secs || !@flag || !@exec_flag
        span_markdown(id, span_exected_at(id))

        @flag = false
        return self
      end

      span_markdown(id)
      self
    end

    def span_mins(mins)
      id = "mins_#{mins}"

      if mins.nil? || (now - span_exected_at(id)) < mins * min || !@flag || !@exec_flag
        span_markdown(id, span_exected_at(id))

        @flag = false
        return self
      end

      span_markdown(id)
      self
    end

    def span_hours(hours)
      id = "hours_#{hours}"

      if hours.nil? || (now - span_exected_at(id)) < hours * hour || !@flag || !@exec_flag
        span_markdown(id, span_exected_at(id))

        @flag = false
        return self
      end

      span_markdown(id)
      self
    end

    def span_days(days)
      id = "days_#{days}"

      if days.nil? || (now - span_exected_at(id)) < days * day || !@flag || !@exec_flag
        span_markdown(id, span_exected_at(id))

        @flag = false
        return self
      end

      span_markdown(id)
      self
    end

    def span_weeks(weeks)
      id = "weeks_#{weeks}"

      if weeks.nil? || (now - span_exected_at(id)) < weeks * week || !@flag || !@exec_flag
        span_markdown(id, span_exected_at(id))

        @flag = false
        return self
      end

      span_markdown(id)
      self
    end

    def span_months(months)
      id = "months_#{months}"

      if months.nil? || (now - span_exected_at(id)) < months * month || !@flag || !@exec_flag
        span_markdown(id, span_exected_at(id))

        @flag = false
        return self
      end

      span_markdown(id)
      self
    end

    def span_years(years)
      id = "years_#{years}"

      if years.nil? || (now - span_exected_at(id)) < years * year || !@flag || !@exec_flag
        span_markdown(id, span_exected_at(id))

        @flag = false
        return self
      end

      span_markdown(id)
      self
    end

    def after_secs(secs)
      return self if secs.nil?
      @flag = true if not_updated_from(secs)
      self
    end

    def after_secs?(secs:, label: nil)
      after_secs(secs).label(label).enabled?
    end

    def after_mins(mins)
      return self if mins.nil?
      time = mins * min
      @flag = true if not_updated_from(time)
      self
    end

    def after_mins?(mins:, label: nil)
      after_mins(mins).label(label).enabled?
    end

    def after_hours(hours)
      return self if hours.nil?
      time = hours * hour
      @flag = true if not_updated_from(time)
      self
    end

    def after_hours?(hours:, label: nil)
      after_hours(hours).label(label).enabled?
    end

    def after_days(days)
      return self if days.nil?
      time = days * day
      @flag = true if not_updated_from(time)
      self
    end

    def after_days?(days:, label: nil)
      after_days(days).label(label).enabled?
    end

    def after_weeks(weeks)
      return self if weeks.nil?
      time = weeks * week
      @flag = true if not_updated_from(time)
      self
    end

    def after_weeks?(weeks:, label: nil)
      after_weeks(weeks).label(label).enabled?
    end

    def after_months(months)
      return self if months.nil?
      time = months * month
      @flag = true if not_updated_from(time)
      self
    end

    def after_months?(months:, label: nil)
      after_months(months).label(label).enabled?
    end

    def after_years(years)
      return self if years.nil?
      time = years * year
      @flag = true if not_updated_from(time)
      self
    end

    def after_years?(years:, label: nil)
      after_years(years).label(label).enabled?
    end

    def dangerfile
      @dangerfile
    end

    def github
      dangerfile.github
    end

    def title
      pr_json[:title]
    end

    def pr_html_url
      pr_json[:html_url]
    end

    def repo_html_url
      pr_json[:base][:repo][:html_url]
    end

    def repo
      pr_json[:base][:repo][:full_name]
    end

    def number
      pr_json[:number]
    end

    def now
      Time.now.to_i
    end

    def sec
      1
    end

    def min
      sec * 60
    end

    def hour
      min * 60
    end

    def day
      hour * 24
    end

    def week
      day * 7
    end

    def month
      day * 30
    end

    def year
      day * 365
    end

    def not_updated_from(time)
      return true if (now - updated_at) >= time
      false
    end

    def updated_at
      commited_at = github.api.pull_request_commits(repo, number)
                      .map { |x| x[:commit][:committer][:date].to_i }
                      .max

      commented_at = github.api.issue_comments(repo, number)
                       .reject { |user| user[:user][:login] =~ /^ap-/ }
                       .map { |x| x[:updated_at].to_i }
                       .max

      review_commented_at = github.api.pull_request_comments(repo, number)
                              .reject { |user| user[:user][:login] =~ /^ap-/ }
                              .map { |x| x[:updated_at].to_i }
                              .max

      pushed_at = pr_json[:head][:repo][:pushed_at].to_i

      [commited_at, commented_at, review_commented_at, pushed_at].compact.max || 0
    end

    #
    # 最後に span が実行された時間を integer で返す
    #
    def span_exected_at(id)
      require "time"

      times = danger_comments
                .map { |c|
        if c[:body] =~ span_regex(id)
          $1.to_i
        else
          nil
        end
      }.compact

      return 0 if times.empty?

      times[0]
    end

    def span_markdown(id, time = Time.now.to_i)
      dangerfile.markdown "<!-- span #{id} #{time} -->"
    end

    def span_regex(id)
      /<!--\sspan\s#{id}\s(.+?)\s-->/
    end

    def danger_comments
      @danger_comments ||= github.api
                             .issue_comments(repo, number)
                             .select { |user| user[:user][:login] == "ap-danger" }
      @danger_comments
    end

    def participants(symbol)
      case symbol
      when :all
        all
      when :reviewers
        reviewers
      when :requested
        requested
      when :commented
        commented
      when :author
        author
      else
        nil
      end
    end

    def all
      [author, reviewers, requested, commented].uniq
    end

    def author
      github.pr_json[:user][:login]
    end

    def reviewers
      github.api.pull_request_reviews(repo, number)
        .map { |x| x[:user][:login] }
        .reject { |user| user =~ /^ap-/ }
        .reject { |user| user == author }
        .uniq
    end

    def requested
      github.api.pull_request_review_requests(repo, number)[:users]
        .map{ |x| x[:login] }
        .reject { |user| user =~ /^ap-/ }
        .uniq
    end

    def commented
      github.api.issue_comments(repo, number)
        .map{ |x| x[:user][:login] }
        .reject { |user| user =~ /^ap-/ }
        .uniq
    end

    def pr_url
      "[[#{repo}](#{repo_html_url})] [##{number} #{title}](#{pr_html_url})"
    end

    def pr_json
      github.pr_json
    end

    def state
      pr_json[:state]
    end

    def closed?
      state == 'closed'
    end
  end

  #
  # Plugin
  #
  class DangerStale < Plugin
    def after_secs(secs)
      StaleState.new(github).after_secs(secs)
    end

    def after_secs?(secs:, label: nil)
      StaleState.new(github).after_secs?(secs: secs, label: label)
    end

    def after_mins(mins)
      StaleState.new(github).after_mins(mins)
    end

    def after_mins?(secs:, label: nil)
      StaleState.new(github).after_mins?(mins: mins, label: label)
    end

    def after_hours(hours)
      StaleState.new(github).after_hours(hours)
    end

    def after_hours?(hours:, label: nil)
      StaleState.new(github).after_hours?(hours: hours, label: label)
    end

    def after_days(days)
      StaleState.new(github).after_days(days)
    end

    def after_days?(days:, label: nil)
      StaleState.new(github).after_days?(days: days, label: label)
    end

    def after_weeks(weeks)
      StaleState.new(github).after_weeks(weeks)
    end

    def after_weeks?(weeks:, label: nil)
      StaleState.new(github).after_weeks?(weeks: weeks, label: label)
    end

    def after_months(months)
      StaleState.new(github).after_months(months)
    end

    def after_months?(months:, label: nil)
      StaleState.new(github).after_months?(months: months, label: label)
    end

    def after_years(years)
      StaleState.new(github).after_years(years)
    end

    def after_years?(years:, label: nil)
      StaleState.new(github).after_years?(years: years, label: label)
    end

    #
    # 互換性維持のために現状はキープ
    # 利用者が0になったら削除
    #
    PERIOD_MSG = "staleプラグインの`period_*`は非推奨になりました。"+
                 "`after_*`をお使いください。([ドキュメント](https://pages.ghe.corp.yahoo.co.jp/hosted-danger/docs/stale.html))"

    def period_secs(secs)
      message PERIOD_MSG
      StaleState.new(github).after_secs(secs)
    end

    def period_secs?(secs:, label: nil)
      message PERIOD_MSG
      StaleState.new(github).after_secs?(secs: secs, label: label)
    end

    def period_mins(mins)
      message PERIOD_MSG
      StaleState.new(github).after_mins(mins)
    end

    def period_mins?(secs:, label: nil)
      message PERIOD_MSG
      StaleState.new(github).after_mins?(mins: mins, label: label)
    end

    def period_hours(hours)
      message PERIOD_MSG
      StaleState.new(github).after_hours(hours)
    end

    def period_hours?(hours:, label: nil)
      message PERIOD_MSG
      StaleState.new(github).after_hours?(hours: hours, label: label)
    end

    def period_days(days)
      message PERIOD_MSG
      StaleState.new(github).after_days(days)
    end

    def period_days?(days:, label: nil)
      message PERIOD_MSG
      StaleState.new(github).after_days?(days: days, label: label)
    end

    def period_weeks(weeks)
      message PERIOD_MSG
      StaleState.new(github).after_weeks(weeks)
    end

    def period_weeks?(weeks:, label: nil)
      message PERIOD_MSG
      StaleState.new(github).after_weeks?(weeks: weeks, label: label)
    end

    def period_months(months)
      message PERIOD_MSG
      StaleState.new(github).after_months(months)
    end

    def period_months?(months:, label: nil)
      message PERIOD_MSG
      StaleState.new(github).after_months?(months: months, label: label)
    end

    def period_years(years)
      message PERIOD_MSG
      StaleState.new(github).after_years(years)
    end

    def period_years?(years:, label: nil)
      message PERIOD_MSG
      StaleState.new(github).after_years?(years: years, label: label)
    end
  end
end
