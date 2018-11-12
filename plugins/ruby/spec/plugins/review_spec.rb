require 'spec_helper'

def not_merge(reason)
  "自動マージはブロックされています (#{reason})"
end

describe Danger::DangerReview do
  subject(:dangerfile) { double('dangerfile') }
  subject(:plugin) { Danger::DangerReview.new(dangerfile) }
  subject(:github) { double('github') }
  let(:api_mock) { double('api') }

  let(:requested_reviewers) { [] }
  let(:author) { "taro" }
  let(:mergeable) { true }
  let(:pr_title) { 'title' }
  let(:pr_json) do
    { "mergeable" => mergeable,
      user: { login: author },
      base: { repo: { full_name: 'repo' } },
      head: { sha: 'shaashasha' },
    }
  end
  let(:errors) { [] }

  before :each do
    allow(dangerfile).to receive(:github).and_return(github)
    allow(dangerfile).to receive(:status_report).and_return({ errors: errors, warnings: [] })
    allow(github).to receive(:api).and_return(api_mock)
    allow(github).to receive(:pr_title).and_return(pr_title)
    allow(github).to receive(:pr_labels).and_return([])
    allow(api_mock).to receive(:pull_request_review_requests).and_return(requested_reviewers)
    allow(github).to receive(:pr_json).and_return(pr_json)
  end

  context 'DangerReview' do
    context 'mergeable?' do
      context 'approved_num' do
        it 'approved_um is nil' do
          expect(dangerfile).to receive(:message).with(not_merge('`review#auto_merge`の引数 approved_num を設定してください'))
          expect(plugin.mergeable?).to eq(false)
        end
      end

      context "not mergeable" do
        let(:mergeable) { false }

        it 'the branch is not mergeable' do
          expect(dangerfile).to receive(:message).with(not_merge('マージ可能な状態ではありません'))
          expect(plugin.mergeable?(approved_num: 2)).to eq(false)
        end
      end

      context 'wip'do
        let(:pr_title) { '[WIP] foo' }
        it 'wip or dnm' do
          expect(dangerfile).to receive(:message).with(not_merge('WIP もしくは DNM です'))
          expect(plugin.mergeable?(approved_num: 2)).to eq(false)
        end
      end

      context "some errors" do
        let(:errors) { [''] }
        it 'Danger has errors or warnings' do
          expect(dangerfile).to receive(:message).with(not_merge('Danger の結果に error もしくは warning があります'))
          expect(plugin.mergeable?(approved_num: 2)).to eq(false)
        end
      end

      context 'there are requested reviewers' do
        let(:requested_reviewers) { ['hoge'] }

        it 'not mergeble' do
          reviews = []

          allow(api_mock).to receive(:pull_request_reviews).and_return(reviews)

          allow(dangerfile).to receive(:status_report).and_return({ errors: [], warnings: [] })

          expect(dangerfile).to receive(:message).with(not_merge('あと 1人の Reviewer の Approve が必要です'))
          expect(plugin.mergeable?(approved_num: 1)).to eq(false)
        end
      end

      it 'current reviews are empty' do
        allow(dangerfile).to receive(:status_report).and_return({ errors: [], warnings: [] })

        reviews = []

        allow(api_mock).to receive(:pull_request_reviews).and_return(reviews)

        expect(dangerfile).to receive(:message).with(not_merge('Reviewer が 設定されていません'))
        expect(plugin.mergeable?(approved_num: 2)).to eq(false)
      end

      it 'there is not success CI status' do
        allow(dangerfile).to receive(:status_report).and_return({ errors: [], warnings: [] })

        reviews = [{ user: { login: 'hoge' }, state: 'APPROVED' }]

        combined_status_mock = double('combined_status')
        allow(combined_status_mock).to receive(:statuses).and_return([ { context: 'hoge', state: 'error' } ])

        allow(api_mock).to receive(:pull_request_reviews).and_return(reviews)
        allow(api_mock).to receive(:combined_status).and_return(combined_status_mock)

        expect(dangerfile).to receive(:message).with(not_merge('Success ではない CI のステータスが存在します'))
        expect(plugin.mergeable?(approved_num: 1)).to eq(false)
      end

      it 'mergeable if all ok' do
        allow(dangerfile).to receive(:status_report).and_return({ errors: [], warnings: [] })

        reviews = [
          { user: { login: 'hoge' }, state: 'APPROVED' },
          { user: { login: 'fuga' }, state: 'APPROVED' },
        ]

        combined_status_mock = double('combined_status')
        allow(combined_status_mock).to receive(:statuses).and_return([ { context: 'hoge', state: 'success' } ])

        allow(api_mock).to receive(:pull_request_reviews).and_return(reviews)
        allow(api_mock).to receive(:combined_status).and_return(combined_status_mock)

        expect(plugin.mergeable?(approved_num: 2)).to eq(true)
      end

      it 'specify number of approves (failed)' do
        allow(dangerfile).to receive(:status_report).and_return({ errors: [], warnings: [] })

        reviews = [{ user: { login: 'hoge' }, state: 'APPROVED' }, { user: { login: 'fuga' }, state: 'APPROVED' }]

        allow(api_mock).to receive(:pull_request_reviews).and_return(reviews)

        expect(dangerfile).to receive(:message).with(not_merge('あと 1人の Reviewer の Approve が必要です'))
        expect(plugin.mergeable?(approved_num: 3)).to eq(false)
      end

      it 'not mergeable when there is request changes with specific approved_num' do
        allow(dangerfile).to receive(:status_report).and_return({ errors: [], warnings: [] })

        reviews = [{ user: { login: 'hoge' }, state: 'APPROVED' }, { user: { login: 'fuga' }, state: 'APPROVED' }, { user: { login: 'hoga' }, state: 'CHANGES_REQUESTED' }]

        allow(api_mock).to receive(:pull_request_reviews).and_return(reviews)

        expect(dangerfile).to receive(:message).with(not_merge('Request changes の Reviewer がいます'))
        expect(plugin.mergeable?(approved_num: 2)).to eq(false)
      end

      it 'mergeable when once approved user requested changes and then reapprove' do
        allow(dangerfile).to receive(:status_report).and_return({ errors: [], warnings: [] })

        reviews = [{ user: { login: 'hoge' }, state: 'APPROVED' }, { user: { login: 'hoge' }, state: 'CHANGES_REQUESTED' }, { user: { login: 'hoge' }, state: 'APPROVED' }]

        combined_status_mock = double('combined_status')
        allow(combined_status_mock).to receive(:statuses).and_return([ { context: 'hoge', state: 'success' } ])
        allow(api_mock).to receive(:combined_status).and_return(combined_status_mock)
        allow(api_mock).to receive(:pull_request_reviews).and_return(reviews)

        expect(plugin.mergeable?(approved_num: 1)).to eq(true)
      end

      it 'the author reviews will be ignored' do
        reviews = [{ user: { login: 'hoge' }, state: 'APPROVED' }, { user: { login: 'fuga' }, state: 'APPROVED' }, { user: { login: author }, state: 'COMMENTED' }]

        combined_status_mock = double('combined_status')
        allow(combined_status_mock).to receive(:statuses).and_return([ { context: 'hoge', state: 'success' } ])

        allow(api_mock).to receive(:pull_request_reviews).and_return(reviews)
        allow(api_mock).to receive(:combined_status).and_return(combined_status_mock)

        expect(plugin.mergeable?(approved_num: 2)).to eq(true)
      end
    end
  end
end
