require "spec_helper"

describe 'Danger::DangerStale' do
  subject(:dangerfile) { double('dangerfile') }
  subject(:plugin) { Danger::StaleState.new(dangerfile) }
  subject(:github) { double('github') }
  subject(:mym) { double('mym') }
  let(:api_mock) { double('api') }
  let(:commit_time) { Time.now.to_i }
  let(:commit) do
    [
      { "commit":
        { "committer":
          { "date": commit_time }
        }
      },
      { "commit":
        { "committer":
          { "date": commit_time - 1 }
        }
      }
    ]
  end
  let(:pr_json) do
    {
      user: { login: 'taro' },
      number: 0,
      base: { repo: { full_name: 'repo' } },
    }
  end


  before :each do
    allow(dangerfile).to receive(:github).and_return(github)
    allow(dangerfile).to receive(:mym).and_return(mym)
    allow(dangerfile).to receive(:message).with(":alarm_clock: Stale 機能が有効です!").and_return("")
    allow(mym).to receive(:post).and_return(true)
    allow(github).to receive(:api).and_return(api_mock)
    allow(github).to receive(:pr_json).and_return(pr_json)
    allow(github).to receive(:pr_labels).and_return(["bug"])
    allow(api_mock).to receive(:issue_comments).and_return([])
    allow(api_mock).to receive(:close_pull_request).and_return(true)
    allow(api_mock).to receive(:add_comment).and_return(true)
    allow(api_mock).to receive(:pull_request_reviews).and_return([])
    allow(api_mock).to receive(:pull_request_review_requests).and_return({users: []})
    allow(api_mock).to receive(:add_labels_to_an_issue).and_return(true)
    allow(api_mock).to receive(:pull_request_commits).and_return(commit)
  end

  context 'DangerStale' do
    context 'time' do
      it 'min' do
        expect(plugin.min).to eq(60)
      end
      it 'hour' do
        expect(plugin.hour).to eq(3600)
      end
      it 'day' do
        expect(plugin.day).to eq(86400)
      end
      it 'week' do
        expect(plugin.week).to eq(604800)
      end
      it 'month' do
        expect(plugin.month).to eq(2592000)
      end
      it 'year' do
        expect(plugin.year).to eq(31536000)
      end
    end

    context 'enabled?' do
      it '@flag true' do
        plugin.instance_variable_set(:@flag, true)
        expect(plugin.enabled?).to eq(true)
      end
      it '@skip true' do
        plugin.instance_variable_set(:@skip, true)
        expect(plugin.enabled?).to eq(false)
      end
    end

    context 'label' do
      it 'exist label' do
        plugin.instance_variable_set(:@flag, true)
        plugin.label("bug")
        expect(plugin.instance_variable_get(:@skip)).to eq(true)
      end
      it 'not exist label' do
        plugin.instance_variable_set(:@flag, true)
        plugin.label("bugi")
        expect(plugin.instance_variable_get(:@skip)).to eq(nil)
        expect(github.api).to have_received(:add_labels_to_an_issue).once
      end
    end

    context 'participants' do
      it 'all' do
        expect(plugin.participants(:all)).to eq(['taro', []])
      end
      it 'author' do
        expect(plugin.participants(:author)).to eq('taro')
      end
      it 'reviewers' do
        reviews = [
          { user: { login: 'ap-danger' }},
          { user: { login: 'taro' } },
          { user: { login: 'jiro' } },
          { user: { login: 'jiro' } },
        ]

        allow(api_mock).to receive(:pull_request_reviews).and_return(reviews)
        expect(plugin.participants(:reviewers)).to eq(['jiro'])
      end
      it 'requested' do
        reviews = {
          'users': [
            { login: 'ap-danger' },
            { login: 'jiro' },
          ]
        }

        allow(api_mock).to receive(:pull_request_review_requests).and_return(reviews)
        expect(plugin.participants(:requested)).to eq(['jiro'])
      end
      it 'commented' do
        reviews = [
          { user: { login: 'ap-danger' }},
          { user: { login: 'taro' } },
          { user: { login: 'jiro' } },
          { user: { login: 'jiro' } },
        ]

        allow(api_mock).to receive(:issue_comments).and_return(reviews)
        expect(plugin.participants(:commented)).to eq(['taro', 'jiro'])
      end
    end

    context 'updated_at' do
      it 'not exist commnet' do
        expect(plugin.updated_at).to eq(commit_time)
      end
      it 'comment > push and sort commented_at' do
        comment_json = [
          {
            user: { login: 'taro' },
            updated_at: commit_time + 1
          },
          {
            user: { login: 'taro' },
            updated_at: commit_time + 2
          }
        ]

        allow(api_mock).to receive(:issue_comments).and_return(comment_json)
        expect(plugin.updated_at).to eq(commit_time + 2)
      end
      it 'push > comment' do
        comment_json = [
           {
             user: { login: 'taro' },
             updated_at: commit_time - 1
           }
        ]

        allow(api_mock).to receive(:issue_comments).and_return(comment_json)
        expect(plugin.updated_at).to eq(commit_time)
      end
    end

    context 'span_exected_at' do
      it 'return 0' do
        expect(plugin.span_exected_at("days_1")).to eq(0)
      end
      it 'success sort' do
        allow(plugin).to receive(:danger_comments).and_return([ { body: "<!-- span days_1 123 -->" } ])
        expect(plugin.span_exected_at("days_1")).to eq(123)
      end

    end

    context 'exec' do
      context 'enabled? is true' do
        before do
          allow(plugin).to receive(:enabled?).and_return(true)
        end
        it 'close' do
          plugin.close
          expect(github.api).to have_received(:close_pull_request).once
        end
        it 'comment' do
          plugin.comment
          expect(github.api).to have_received(:add_comment).once
        end
        it 'comment (with named arg)' do
          plugin.comment(comment: 'hoge')
          expect(github.api).to have_received(:add_comment).once
        end
        it 'comment_with_mentions' do
          plugin.comment_with_mentions
          expect(github.api).to have_received(:add_comment).once
        end
        it 'mym' do
          plugin.mym
          expect(dangerfile.mym).to have_received(:post).once
        end
        it 'mym_with_mentions' do
          plugin.mym_with_mentions
          expect(dangerfile.mym).to have_received(:post).once
        end
      end
      context 'enabled? is false' do
        before do
          allow(plugin).to receive(:enabled?).and_return(false)
        end
        it 'close' do
          plugin.close
          expect(github.api).to have_received(:close_pull_request).exactly(0).times
        end
        it 'comment' do
          plugin.comment
          expect(github.api).to have_received(:add_comment).exactly(0).times
        end
        it 'comment_with_mentions' do
          plugin.comment_with_mentions
          expect(github.api).to have_received(:add_comment).exactly(0).times
        end
        it 'mym' do
          plugin.mym
          expect(dangerfile.mym).to have_received(:post).exactly(0).times
        end
        it 'mym_with_mentions' do
          plugin.mym_with_mentions
          expect(dangerfile.mym).to have_received(:post).exactly(0).times
        end
      end
    end

    context 'span_*' do
      #
      # 値が更新されるパターン
      #
      context '@flag true' do
        before do
          allow(Time).to receive(:now).and_return(100000000000000)
          plugin.instance_variable_set(:@flag, true)
          allow(dangerfile).to receive(:markdown).with(/^<!--/).and_return("")
        end
        it 'span_secs' do
          expect(plugin).to receive(:span_markdown).with("secs_1")
          plugin.span_secs(1)
        end
        it 'span_mins' do
          expect(plugin).to receive(:span_markdown).with("mins_1")
          plugin.span_mins(1)
        end
        it 'span_hours' do
          expect(plugin).to receive(:span_markdown).with("hours_1")
          plugin.span_hours(1)
        end
        it 'span_days' do
          expect(plugin).to receive(:span_markdown).with("days_1")
          plugin.span_days(1)
        end
        it 'span_weeks' do
          expect(plugin).to receive(:span_markdown).with("weeks_1")
          plugin.span_weeks(1)
        end
        it 'span_months' do
          expect(plugin).to receive(:span_markdown).with("months_1")
          plugin.span_months(1)
        end
        it 'span_years' do
          expect(plugin).to receive(:span_markdown).with("years_1")
          plugin.span_years(1)
        end
      end

      #
      # 値が更新されないパターン
      #
      context '@flag nil' do
        before do
          allow(Time).to receive(:now).and_return(100000000000000)
          allow(dangerfile).to receive(:markdown).with(/^<!--/).and_return("")
        end
        it 'span_secs' do
          expect(plugin).to receive(:span_markdown).with("secs_1", 0)
          plugin.span_secs(1)
        end
        it 'span_mins' do
          expect(plugin).to receive(:span_markdown).with("mins_1", 0)
          plugin.span_mins(1)
        end
        it 'span_hours' do
          expect(plugin).to receive(:span_markdown).with("hours_1", 0)
          plugin.span_hours(1)
        end
        it 'span_days' do
          expect(plugin).to receive(:span_markdown).with("days_1", 0)
          plugin.span_days(1)
        end
        it 'span_weeks' do
          expect(plugin).to receive(:span_markdown).with("weeks_1", 0)
          plugin.span_weeks(1)
        end
        it 'span_months' do
          expect(plugin).to receive(:span_markdown).with("months_1", 0)
          plugin.span_months(1)
        end
        it 'span_years' do
          expect(plugin).to receive(:span_markdown).with("years_1", 0)
          plugin.span_years(1)
        end
      end

      #
      # 値が更新されないパターン
      #
      context '@flag true and span > time' do
        let(:time) { 100 }
        let(:comment_json){[]}
        before do
          allow(Time).to receive(:now).and_return(1)
          plugin.instance_variable_set(:@flag, true)
          allow(plugin).to receive(:danger_comments).and_return(comment_json)
          allow(dangerfile).to receive(:markdown).with(/^<!--/).and_return("")
        end

        it 'span_secs' do
          comment_json.push(body: "<!-- span secs_1 #{time} -->")
          expect(plugin).to receive(:span_markdown).with("secs_1", time)
          plugin.span_secs(1)
        end
        it 'span_mins' do
          comment_json.push(body: "<!-- span mins_1 #{time} -->")
          expect(plugin).to receive(:span_markdown).with("mins_1", time)
          plugin.span_mins(1)
        end
        it 'span_hours' do
          comment_json.push(body: "<!-- span hours_1 #{time} -->")
          expect(plugin).to receive(:span_markdown).with("hours_1", time)
          plugin.span_hours(1)
        end
        it 'span_days' do
          comment_json.push(body: "<!-- span days_1 #{time} -->")
          expect(plugin).to receive(:span_markdown).with("days_1", time)
          plugin.span_days(1)
        end
        it 'span_weeks' do
          comment_json.push(body: "<!-- span weeks_1 #{time} -->")
          expect(plugin).to receive(:span_markdown).with("weeks_1", time)
          plugin.span_weeks(1)
        end
        it 'span_months' do
          comment_json.push(body: "<!-- span months_1 #{time} -->")
          expect(plugin).to receive(:span_markdown).with("months_1", time)
          plugin.span_months(1)
        end
        it 'span_years' do
          comment_json.push(body: "<!-- span years_1 #{time} -->")
          expect(plugin).to receive(:span_markdown).with("years_1", time)
          plugin.span_years(1)
        end
      end
    end

    context 'after_*' do
      context 'success' do
        let(:commit_time) { Time.now.to_i - 1 * plugin.year }
        it 'true after_secs' do
          plugin.after_secs(31536000)
          expect(plugin.instance_variable_get(:@flag)).to eq(true)
        end
        it 'true after_mins' do
          plugin.after_mins(525600)
          expect(plugin.instance_variable_get(:@flag)).to eq(true)
        end
        it 'true after_hours' do
          plugin.after_hours(8760)
          expect(plugin.instance_variable_get(:@flag)).to eq(true)
        end
        it 'true after_days' do
          plugin.after_days(365)
          expect(plugin.instance_variable_get(:@flag)).to eq(true)
        end
        it 'true after_weeks' do
          plugin.after_weeks(52)
          expect(plugin.instance_variable_get(:@flag)).to eq(true)
        end
        it 'true after_months' do
          plugin.after_months(12)
          expect(plugin.instance_variable_get(:@flag)).to eq(true)
        end
        it 'true after_years' do
          plugin.after_years(1)
          expect(plugin.instance_variable_get(:@flag)).to eq(true)
        end
      end

      context 'fail' do
        let(:commit_time) { Time.now.to_i - 1 * plugin.year + 1 }
        it 'false after_secs' do
          plugin.after_secs(31536000)
          expect(plugin.instance_variable_get(:@flag)).to eq(nil)
        end
        it 'false after_mins' do
          plugin.after_mins(525600)
          expect(plugin.instance_variable_get(:@flag)).to eq(nil)
        end
        it 'false after_hours' do
          plugin.after_hours(8760)
          expect(plugin.instance_variable_get(:@flag)).to eq(nil)
        end
        it 'false after_days' do
          plugin.after_days(365)
          expect(plugin.instance_variable_get(:@flag)).to eq(nil)
        end
        it 'false after_weeks' do
          plugin.after_weeks(53)
          expect(plugin.instance_variable_get(:@flag)).to eq(nil)
        end
        it 'false after_months' do
          plugin.after_months(13)
          expect(plugin.instance_variable_get(:@flag)).to eq(nil)
        end
        it 'false after_years' do
          plugin.after_years(1)
          expect(plugin.instance_variable_get(:@flag)).to eq(nil)
        end
      end
    end

    context 'exec_if' do
      context 'peroid_* true' do
        before do
          allow(plugin).to receive(:after_secs).and_return(plugin)
          plugin.instance_variable_set(:@flag, true)
        end
        it 'exec_if true => enabled? true' do
          expect(plugin.after_secs(1).exec_if { true }.enabled?).to eq(true)
        end

        it 'exec_if false => enabled? false' do
          expect(plugin.after_secs(1).exec_if { false }.enabled?).to eq(false)
        end
      end

      context 'peroid_* false' do
        before do
          allow(plugin).to receive(:after_secs).and_return(plugin)
          plugin.instance_variable_set(:@flag, false)
        end
        it 'exec_if true => enabled? false' do
          expect(plugin.after_secs(1).exec_if { true }.enabled?).to eq(false)
        end

        it 'exec_if false => enabled? false' do
          expect(plugin.after_secs(1).exec_if { false }.enabled?).to eq(false)
        end
      end
    end
  end
end
