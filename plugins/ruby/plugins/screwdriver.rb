require 'net/https'
require 'json'
require 'tempfile'
require 'time'

module Danger
  #
  # 全体像
  #
  # - DangerScrewdriver プラグイン本体
  #
  # - Screwdriver       Screwdriverにアクセスするインスタンス
  #   - Build           Screwdriver Buildに紐づくインスタンス
  #
  # DangerScrewdriver, Screwdriver, Build 共通で使用する module
  #
  module ScrewdriverCommon
    def pure_job_name(job_name)
      if job_name =~ /PR-\d+:/
        return job_name.sub(/PR-\d+:/, '')
      end

      #
      # ~pr がトリガーでないジョブは (commit) suffixをつけて返す
      #
      "#{job_name} (commit)"
    end

    def string_to_regexp(path)
      if path.is_a?(String)
        escaped = Regexp.escape(path).gsub('\*','.*?')
        return Regexp.new("^#{escaped}$", Regexp::IGNORECASE)
      end

      path
    end
  end

  #
  # Plugin本体
  #
  class DangerScrewdriver < Plugin

    def check_status
      return unless sd?

      total = head.context[:statuses].count
      errors = head.context[:statuses].count { |x| x[:state] =~ /error|failure/ }
      pendings = head.context[:statuses].count {|x| x[:state] =~ /pending/ }

      return warn 'Waiting for Screwdriver builds to start :gear:' if total.zero?
      return fail "Screwdriver builds failed #{errors} / #{total} :fearful:" if errors > 0
      return warn "Screwdriver builds are running #{pendings} / #{total} :running:" if pendings > 0
    end

    def report_summary
      table_headers = [:job_name, :status, :duration]
      table_rows = []

      coverage_diff = nil

      head.context[:builds].each do |build|
        table_row_build = build.report

        if reports = build.find_test_reports
          head_result = test_report.parse(reports.map { |r| head.auth_get(r) })
          base_result = test_report.parse(base.test_report_files)
          test_html = build.test_report_html

          summary = test_report.summary_text_with_diff(head_result, base_result)
          table_row_build[:test] = test_html ? "[#{summary}](#{test_html})" : summary
        end

        if report = build.find_coverage_report
          head_result = code_coverage.parse(head.auth_get(report))
          base_result = code_coverage.parse(base.coverage_report_file)
          coverage_html = build.coverage_report_html

          summary = code_coverage.summary_text_with_diff(head_result, base_result)
          table_row_build[:coverage] = coverage_html ? "[#{summary}](#{coverage_html})" : summary

          coverage_diff = create_coverage_diff(head_result, base_result)
        end

        table_rows << table_row_build
      end

      table_headers << :test if table_rows.any? { |row| row[:test] }
      table_headers << :coverage if table_rows.any? { |row| row[:coverage] }

      header = table_rows.empty? ? nil : "## Screwdriver Build Summary"

      table_markdown = table_rows.empty? ? nil :
                         table_headers.map { |h| header_names[h] }.join(" | ") + "\n" +
                         table_headers.map { |_| ":--:" }.join(" | ") + "\n" +
                         table_rows.map { |r| table_headers.map { |h| r[h] || '-' }.join(" | ") }.join("\n")

      last_update = coverage_diff.nil? ? nil : "> Last update [##{base.sha_short}](#{base.sha_url}) .. [##{head.sha_short}](#{head.sha_url})"

      report_markdown = [
        header,
        table_markdown,
        coverage_diff,
        last_update,
      ].compact.join("\n")

      markdown(report_markdown)

      #
      # meta の danger.* に格納されている情報を表示
      # 主にリポートURLの表示に使用する
      #
      meta_all
    end

    #
    # 全ての meta の処理をデフォルトprefixで実行する
    #
    def meta_all
      meta_markdown
      meta_message
      meta_warn
      meta_fail
    end

    #
    # screwdriver の meta に格納されたデータを markdown で表示
    # danger.markdown.[任意のkey] という形式で格納する
    #
    def meta_markdown(target_prefix = 'danger.markdown')
      meta_contents = collect_metas(target_prefix)

      return if meta_contents.nil? || meta_contents.size.zero?

      markdowns = meta_contents
                    .select { |k, v| v.is_a?(String) }
                    .map { |k, v| v.gsub('\n', "\n") }
                    .join("\n")

      markdown(markdowns)
    end

    def meta_message(target_prefix = 'danger.message')
      meta_contents = collect_metas(target_prefix)

      return if meta_contents.nil? || meta_contents.size.zero?

      messages = meta_contents
                   .select { |k, v| v.is_a?(String) }
                   .map { |k, v| v.gsub('\n', "\n") }
      messages.each do |m|
        message m
      end
    end

    def meta_warn(target_prefix = 'danger.warn')
      meta_contents = collect_metas(target_prefix)

      return if meta_contents.nil? || meta_contents.size.zero?

      warns = meta_contents
                .select { |k, v| v.is_a?(String) }
                .map { |k, v| v.gsub('\n', "\n") }
      warns.each do |w|
        warn w
      end
    end

    def meta_fail(target_prefix = 'danger.fail')
      meta_contents = collect_metas(target_prefix)

      return if meta_contents.nil? || meta_contents.size.zero?

      fails = meta_contents
                .select { |k, v| v.is_a?(String) }
                .map { |k, v| v.gsub('\n', "\n") }
      fails.each do |f|
        fail f
      end
    end

    #
    # target_prefix に対応する全ての meta を Hash で返す
    #
    def collect_metas(target_prefix)
      build_metas = metas.map { |m| collect_meta(m, target_prefix) }.compact
      return {} if build_metas.size.zero?

      res = build_metas.first

      build_metas.drop(1).each do |m|
        res.merge!(m)
      end

      res
    end

    #
    # target_prefix に対応する meta を Hash で返す
    # 該当するものがない場合は nil
    #
    def collect_meta(meta, target_prefix)
      target_prefix = target_prefix.split('.')
      target_prefix.each do |key|
        return nil unless meta.is_a?(Hash)
        return nil unless meta.include?(key)
        meta = meta[key]
      end

      return nil unless meta.is_a?(Hash)
      return nil if meta.size.zero?

      meta
    end

    def create_coverage_diff(head_result, base_result)
      #
      # *_result の形式は以下
      # { line_rate: Float, files: [{ file: String, coverage: Float }] }
      #
      return nil if head_result.nil? || base_result.nil?

      #
      # head もしくは base に含まれる uniq な file 名
      #
      files = [head_result[:files], base_result[:files]].flatten.map { |r| r[:file] }.uniq

      #
      # files を以下の形式に変換
      # [{ file: String, base: Float, head: Float, diff: Float }]
      #
      # head もしくは base に 対象の file がない場合は coverage == 0 として扱う
      #
      diffs = files.map do |f|
        #
        # *_exist はそれぞれの ref にファイルが存在ししているか (Bool)
        #
        h = if result = head_result[:files].find { |h| h[:file] == f }
              h_exist = true
              result
            else
              h_exist = false
              { file: f, coverage: 0.0 }
            end

        b = if result = base_result[:files].find { |b| b[:file] == f }
              b_exist = true
              result
            else
              b_exist = false
              { file: f, coverage: 0.0 }
            end

        {
          file: f,
          head: h[:coverage],
          base: b[:coverage],
          diff: h[:coverage] - b[:coverage],
          new: h_exist && !b_exist, # 新規ファイル (Bool)
        }
      end

      new_diffs = diffs
                    .select { |r| r[:new] } # 新規追加された
                    .sort_by { |r| r[:diff] }

      neg_diffs = diffs
                    .select { |r| r[:diff] < 0 } # diff がマイナスのもの
                    .sort_by { |r| r[:diff] }

      pos_diffs = diffs
                    .select { |r| r[:diff] > 0 && !r[:new] } # diff がプラスのもの && 新規ファイルではない
                    .sort_by { |r| -r[:diff] }

      diff_table = DiffTable.new

      if new_diffs.size > 0
        diff_table.header('New Files', 'Coverage', '+/-')

        new_diffs.first(10).each do |diff|
          diff_table.diff(diff[:file], (diff[:head] * 100).round(2), (diff[:diff] * 100).round(2), '%', true)
        end

        diff_table.comment("... total impacted files: #{new_diffs.size}") if new_diffs.size > 10
      end

      diff_table.empty if new_diffs.size > 0 && (neg_diffs.size > 0 && pos_diffs.size > 0)

      if neg_diffs.size > 0
        diff_table.header('Negative Impacted Files', 'Coverage', '+/-')

        neg_diffs.first(10).each do |diff|
          diff_table.diff(diff[:file], (diff[:head] * 100).round(2), (diff[:diff] * 100).round(2), '%')
        end

        diff_table.comment("... total impacted files: #{neg_diffs.size}") if neg_diffs.size > 10
      end

      diff_table.empty if (new_diffs.size > 0 || neg_diffs.size > 0) && pos_diffs.size > 0

      if pos_diffs.size > 0
        diff_table.header('Positive Impacted Files', 'Coverage', '+/-')

        pos_diffs.first(10).each do |diff|
          diff_table.diff(diff[:file], (diff[:head] * 100).round(2), (diff[:diff] * 100).round(2), '%')
        end

        diff_table.comment("... total impacted files: #{pos_diffs.size}") if pos_diffs.size > 10
      end

      diff_table.create
    end

    def header_names
      {
        job_name: "Job",
        status: "Status",
        duration: "Duration",
        test: "Test",
        coverage: "Coverage",
      }
    end

    def activate_chatops
      return unless sd?
      return unless ENV['DANGER_EVENT'] == 'issue_comment'

      if ENV['DANGER_PR_COMMENT'] =~ /^@ap-danger\s+sd\s+(.+)$/
        head.exec_job($1.to_s)
      end
    end

    #
    # HEAD と BASE の情報を保持する Screwdriver インスタンス
    #
    @head = nil
    @base = nil

    def head
      return @head if @head

      @head = Screwdriver.new(github, :head)
      @head
    end

    def base
      return @base if @base

      @base = Screwdriver.new(github, :base)
      @base
    end

    def sd?
      File.exist?("#{Dir.pwd}/screwdriver.yaml")
    end

    #
    # HEAD の meta (Build ごとの meta を配列で返す)
    #
    def metas
      return [] unless sd?

      head.context[:builds]
        .select { |b| b.detail }
        .map { |b| b.detail['meta'] }.compact
    end

    #
    # 直接 Artifacts から落としたファイルを触りたい人用
    #
    def artifact(path, job_name = nil, &block)
      return unless sd?

      path = string_to_regexp(path)

      if artifact = head.context[:builds]
                      .select { |b| b.job_name == job_name || !job_name }
                      .map { |b| b.artifacts }.flatten.compact
                      .find { |artifact| artifact.split('artifacts/')[1] =~ path }
        Tempfile.create('artifact') do |file|
          file.write(head.auth_get(artifact))
          file.flush

          yield file.path, artifact
        end
      end
    end

    #
    # 直接 Artifacts から落としたファイルを触りたい人用
    #
    def artifacts(path, job_name = nil, &block)
      return unless sd?

      path = string_to_regexp(path)

      if artifacts = head.context[:builds]
                       .select { |b| b.job_name == job_name || !job_name }
                       .map { |b| b.artifacts }.flatten.compact
                       .select { |artifact| artifact.split('artifacts/')[1] =~ path }
        artifacts.each do |artifact|
          Tempfile.create('artifact') do |file|
            file.write(head.auth_get(artifact))
            file.flush

            yield file.path, artifact
          end
        end
      end
    end

    include ScrewdriverCommon
  end

  class Screwdriver
    #
    # @contextの中身
    # - :statuses    Array(*1)      Screwdriverに関係するステータス
    # - :next        Bool           next なら true, cd なら false
    # - :pipeline_id String         パイプラインID
    # - :builds      Array(Build*2) ビルドID
    #
    # *1: https://developer.github.com/v3/repos/statuses/#get-the-combined-status-for-a-specific-ref
    # *2: 後述のBuild class
    #
    @context = nil

    #
    # jobの配列 ScrewdriverのAPIを叩く必要があるため、Contextには含ませない
    #
    @jobs = nil

    def initialize(github, ref)
      @github = github
      @ref = ref
    end

    def repo
      @github.pr_json[:base][:repo][:full_name]
    end

    def html_url
      @github.pr_json[@ref][:repo][:html_url]
    end

    def pr_number
      @github.pr_json[:number]
    end

    def sha
      @github.pr_json[@ref][:sha]
    end

    def sha_short
      sha[0..6]
    end

    def sha_url
      "#{html_url}/commit/#{sha}"
    end

    def branch
      @github.pr_json[@ref][:ref]
    end

    def context
      return @context if @context

      statuses = @github.api
                   .combined_status(repo, sha)
                   .statuses
                   .select { |x| x[:context].match(/^Screwdriver/i) }

      @context = {}
      @context[:statuses] = statuses
      @context[:builds] ||= []

      statuses.each do |status|
        if status[:target_url] =~
           /https:\/\/(.+?)\.screwdriver\.corp\.yahoo\.co\.jp\/pipelines\/(.+?)\/builds\/(.+?)$/

          @context[:next] = $1.to_s == 'next'
          @context[:pipeline_id] ||= $2.to_s
          @context[:builds].push(Build.new(self, $3.to_s, status[:state]))
        end
      end

      @context
    end

    def jobs
      return @jobs if @jobs

      @jobs = JSON.parse(auth_get("#{endpoint}/pipelines/#{context[:pipeline_id]}/jobs"))
      @jobs
    end

    def coverage_report_file
      reports = context[:builds].map { |b| b.find_coverage_report }.compact
      return nil if reports.size.zero?

      auth_get(reports[0])
    end

    def test_report_files
      reports = context[:builds].map { |b| b.find_test_reports }.flatten.compact
      return nil if reports.size.zero?

      reports.map { |r| auth_get(r) }
    end

    def endpoint
      return 'https://api-next.screwdriver.corp.yahoo.co.jp/v4' if context[:next]
      'https://api-cd.screwdriver.corp.yahoo.co.jp/v4'
    end

    def webui
      return 'https://next.screwdriver.corp.yahoo.co.jp' if context[:next]
      'https://cd.screwdriver.corp.yahoo.co.jp'
    end

    def auth_get(url, ignore_error = false)
      auth_request(Net::HTTP::Get, url, nil, ignore_error)
    end

    def auth_post(url, body, ignore_error = false)
      auth_request(Net::HTTP::Post, url, body, ignore_error)
    end

    def auth_request(request, url, body, ignore_error)
      uri = URI.parse(url)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      req = request.new(uri.request_uri)
      req['Accept'] = 'application/json'
      req['Authorization'] = "Bearer #{jwt_token}"

      if request == Net::HTTP::Post
        req['Content-Type'] = 'application/json'
        req.body = body
      end

      res = http.request(req)

      case res
      when Net::HTTPSuccess then return res.body
      when Net::HTTPRedirection then return auth_request(request, res['location'], body, ignore_error)
      else
        raise "error during calling Screwdriver API #{res.code} (#{request}, #{url})" unless ignore_error
      end

      nil
    end

    def jwt_token
      return ENV['SD_JWT_TOKEN'] if ENV['SD_JWT_TOKEN']
      return @jwt_token if @jwt_token

      localhost = "http://localhost/sdproxy/auth"
      localhost += "/next" if context[:next]

      jwt_token_raw = Net::HTTP.get URI.parse(localhost)
      jwt_token_json = JSON.parse(jwt_token_raw)

      @jwt_token = jwt_token_json['token']
      @jwt_token
    end

    def exec_job(job_name)
      if jobs.any? { |job| job['name'] == "PR-#{pr_number}:#{job_name}" }
        #
        # jobの実行
        #
        body = {
          causeMessage: "Started by Hosted Danger",
          pipelineId: context[:pipeline_id],
          startFrom: "PR-#{pr_number}:#{job_name}",
        }.to_json

        auth_post("#{endpoint}/events", body)

        @github.api.add_comment(repo, pr_number, "**#{job_name}** を開始しました")

        return
      end

      job_names = jobs.map { |job| pure_job_name(job['name']) }.compact.uniq.join("\n")

      comment = <<-COMMENT
**#{job_name}** が見つかりませんでした。

利用可能なjobのリストです。
#{job_names}
COMMENT

      @github.api.add_comment(repo, pr_number, comment)
    end

    include ScrewdriverCommon
  end

  #
  # Build情報を保持する
  #
  class Build
    attr_reader :id, :state

    #
    # Build 詳細
    #
    @detail = nil

    #
    # Build に紐づく Job の情報
    #
    @job = nil

    #
    # Build に紐づく Artifacts
    #
    @artifacts = nil

    def initialize(sd, id, state)
      @sd = sd
      @id = id
      @state = state
    end

    #
    # target に対応する meta の値を返す
    # 該当するものがない場合は nil
    #
    def meta_value(target)
      return nil unless detail

      meta = detail['meta']

      return nil unless meta

      target_prefix = target.split('.')
      target_prefix.each do |key|
        return nil unless meta.is_a?(Hash)
        return nil unless meta.include?(key)
        meta = meta[key]
      end

      meta
    end

    #
    # report_summary に使用する report 結果の取得
    # {
    #   job_name:        String,
    #   status:          String (絵文字),
    #   duration:        Int (sec),
    # }
    #
    def report
      {
        job_name: job_name_log_link,
        status: status_emoji,
        duration: duration,
      }
    end

    #
    # 注意: 実行のタイミングによっては nil が返る
    #
    def detail
      return @detail if @detail
      return nil unless res = @sd.auth_get("#{@sd.endpoint}/builds/#{@id}", true)

      @detail = JSON.parse(res)
      @detail
    end

    #
    # 注意: 実行のタイミングによっては nil が返る
    #
    def job
      return @job if @job
      return nil unless detail

      @job = JSON.parse(@sd.auth_get("#{@sd.endpoint}/jobs/#{detail['jobId']}"))
      @job
    end

    #
    # manifests.txt が未アップロードの場合 nil が返る
    #
    def artifacts
      return @artifacts if @artifacts

      manifests = @sd.auth_get("#{@sd.endpoint}/builds/#{@id}/artifacts/manifest.txt", true)

      #
      # manifests.txt が用意できていない
      #
      return nil unless manifests

      @artifacts = manifests.split("\n")
                     .select { |file| file.start_with?("./") }
                     .map { |file| file[2..-1] }
                     .map { |file| "#{@sd.endpoint}/builds/#{@id}/artifacts/#{file}" }.flatten.compact
      @artifacts
    end

    def job_name_log_link
      "[#{job_name}](#{log_link})"
    end

    def job_name
      return 'unknown' unless job
      pure_job_name(job['name'])
    end

    def duration
      if finished? && detail['startTime'] && detail['endTime']
        s = Time.parse(detail['startTime'])
        e = Time.parse(detail['endTime'])

        return duration_pretty((e - s).to_i)
      end

      '-'
    end

    def duration_pretty(duration, prefix = '')
      if duration > 60 * 60
        duration_pretty(duration % (60 * 60), "#{duration / (60 * 60)}h ")
      elsif duration > 60
        duration_pretty(duration % 60, prefix + "#{duration / 60}m ")
      else
        prefix + "#{duration}s"
      end
    end

    def status_emoji
      return '-' unless detail

      case detail['status']
      when 'QUEUED'
        ':zzz:'
      when 'RUNNING'
        ':running:'
      when 'SUCCESS'
        ':white_check_mark:'
      when 'ABORTED'
        ':no_entry_sign:'
      when 'FAILURE'
        ':x:'
      else
        ':question:'
      end
    end

    def log_link
      "#{@sd.webui}/pipelines/#{@sd.context[:pipeline_id]}/builds/#{@id}"
    end

    #
    # 複数の Junit ファイルが存在する可能性があるので
    # レポートが存在する場合は Array で返す
    # レポートが存在しない場合は nil を返す
    #
    def find_test_reports
      return nil unless artifacts

      patterns = [
        # iOS, etc
        %r{^reports/test/.*\.xml$},
        %r{^reports/test/.*\.junit$},

        # Android
        %r{build/test-results/.*\.xml$},
      ]

      res = patterns.map do |pattern|
        artifacts.map do |artifact|
          path = artifact.split('artifacts/')[1]

          if m = pattern.match(path)
            artifact
          else
            nil
          end
        end
      end.flatten.compact

      #
      # レポートが見つからなかった
      #
      return nil if res.size.zero?

      res
    end

    def find_coverage_report
      return nil unless artifacts

      files = "([^/]+\.xml)"

      patterns = [
        # iOS, etc
        %r{^reports/coverage/#{files}$},

        # Android
        %r{build/reports/jacoco/.+/#{files}$},
      ]

      patterns.each do |pattern|
        artifacts.each do |artifact|
          path = artifact.split('artifacts/')[1]

          if m = pattern.match(path)
            return artifact
          end
        end
      end

      nil
    end

    def test_report_html
      meta_value("#{id}.test_report.html")
    end

    def coverage_report_html
      meta_value("#{id}.coverage_report.html")
    end

    def finished?
      return false unless detail
      detail['status'] != 'QUEUED' && detail['status'] != 'RUNNING'
    end

    include ScrewdriverCommon
  end

  class DiffTable
    TITLE_LEN = 60
    HEAD_LEN  = 10
    DIFF_LEN  = 10

    def initialize
      @rows = []
    end

    def header(title, head, diff)
      @rows << "## #{row(title, head, diff)}"
      @rows << bar
      self
    end

    def bar
      "===#{row('=' * TITLE_LEN, '=' * HEAD_LEN, '=' * DIFF_LEN, '=')}"
    end

    def empty
      @rows << ""
      self
    end

    #
    # head, diff は数値
    # include_zero: 0 を '-' に含むか否か (new files に利用している)
    #
    def diff(title, head, diff, unit, include_zero = false)
      head_text = "#{head}#{unit}"
      diff_text = "#{diff}#{unit}"
      diff_text = "+#{diff_text}" if diff > 0

      sign = if diff == 0
               if include_zero
                 '-'
               else
                 ' '
               end
             elsif diff > 0
               '+'
             else # diff < 0
               '-'
             end

      @rows << "#{sign}  #{row(title, head_text, diff_text)}"
      self
    end

    def comment(comment)
      @rows << "## %#{TITLE_LEN + HEAD_LEN + DIFF_LEN + 2}s" % [comment]
      self
    end

    def row(title, head, diff, delimiter = ' ')
      title = title.to_s
      title = '...' + title[-TITLE_LEN+3..-1] if title.size > TITLE_LEN

      head = head.to_s
      head = '...' + head[-HEAD_LEN+3..-1] if head.size > HEAD_LEN

      diff = diff.to_s
      diff = '...' + diff[-DIFF_LEN+3..-1] if diff.size > DIFF_LEN

      "%-#{TITLE_LEN}s#{delimiter}%#{HEAD_LEN}s#{delimiter}%#{DIFF_LEN}s" % [title, head, diff]
    end

    def create
      return nil if @rows.size.zero?
      "```diff\n#{@rows.join("\n")}\n```\n"
    end
  end
end
