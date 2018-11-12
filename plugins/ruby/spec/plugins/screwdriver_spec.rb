require 'spec_helper'

describe Danger::DangerScrewdriver do

  subject(:dangerfile) { double('dangerfile') }
  subject(:plugin) { Danger::DangerScrewdriver.new(dangerfile) }
  subject(:github) { double('github') }
  subject(:pr_json) { {
                        number: 1,
                        head: {
                          sha: 'abc',
                        },
                        base: {
                          sha: 'def',
                          repo: {
                            full_name: 'hoge/fuga',
                          },
                        },
                      } }

  before :each do
    allow(plugin).to receive(:sd?).and_return(true)
    allow(github).to receive(:pr_json).and_return(pr_json)
    allow(dangerfile).to receive(:github).and_return(github)
  end

  context 'DangerScrewdriver' do
    context 'check_status' do
      it 'no errors and warnings' do
        allow(plugin.head).to receive(:context).and_return({ statuses: [{ state: 'success' }] })

        expect(dangerfile).not_to receive(:warn)
        expect(dangerfile).not_to receive(:fail)

        plugin.check_status
      end

      it 'waiting' do
        allow(plugin.head).to receive(:context).and_return({ statuses: [] })

        expect(dangerfile).to receive(:warn).with('Waiting for Screwdriver builds to start :gear:')
        expect(dangerfile).not_to receive(:fail)

        plugin.check_status
      end

      context 'error or failure' do
        it 'error' do
          allow(plugin.head).to receive(:context).and_return({ statuses: [{ state: 'error' }] })

          expect(dangerfile).not_to receive(:warn)
          expect(dangerfile).to receive(:fail).with('Screwdriver builds failed 1 / 1 :fearful:')

          plugin.check_status
        end

        it 'failure' do
          allow(plugin.head).to receive(:context).and_return({ statuses: [{ state: 'failure' }] })

          expect(dangerfile).not_to receive(:warn)
          expect(dangerfile).to receive(:fail).with('Screwdriver builds failed 1 / 1 :fearful:')

          plugin.check_status
        end
      end

      it 'running' do
        allow(plugin.head).to receive(:context).and_return({ statuses: [{ state: 'pending' }] })

        expect(dangerfile).to receive(:warn).with('Screwdriver builds are running 1 / 1 :running:')
        expect(dangerfile).not_to receive(:fail)

        plugin.check_status
      end
    end

    context 'report_summary' do

      it 'success with test and coverage reports' do
        build_mock = double('build')
        allow(build_mock).to receive(:report).and_return({ job_name: 'job', status: ':sunny:', duration: '10s' })
        allow(build_mock).to receive(:find_test_reports).and_return(['test_report'])
        allow(build_mock).to receive(:find_coverage_report).and_return('coverage_report')
        allow(build_mock).to receive(:test_report_html).and_return('test_report_html')
        allow(build_mock).to receive(:coverage_report_html).and_return('coverage_report_html')

        context = { builds: [build_mock] }
        allow(plugin.head).to receive(:context).and_return(context)
        allow(plugin.head).to receive(:auth_get)
        allow(plugin.head).to receive(:sha_url).and_return('http://hoge.com')
        allow(plugin.head).to receive(:sha_short).and_return('#1234567')

        allow(plugin.base).to receive(:test_report_files).and_return(['test_report'])
        allow(plugin.base).to receive(:coverage_report_file).and_return('coverage_report')
        allow(plugin.base).to receive(:sha_url).and_return('http://hoge.com')
        allow(plugin.base).to receive(:sha_short).and_return('#1234567')

        test_report_mock = double('test_report')
        allow(test_report_mock).to receive(:parse).and_return('parsed')
        allow(test_report_mock).to receive(:summary_text_with_diff).and_return('test')

        code_coverage_mock = double('code_coverage')
        allow(code_coverage_mock).to receive(:parse).and_return('parsed')
        allow(code_coverage_mock).to receive(:summary_text_with_diff).and_return('coverage')

        allow(plugin).to receive(:create_coverage_diff).and_return('diff')

        allow(dangerfile).to receive(:test_report).and_return(test_report_mock)
        allow(dangerfile).to receive(:code_coverage).and_return(code_coverage_mock)
        allow(plugin).to receive(:meta_all).and_return(nil)

        expect(dangerfile).to receive(:markdown).with('## Screwdriver Build Summary
Job | Status | Duration | Test | Coverage
:--: | :--: | :--: | :--: | :--:
job | :sunny: | 10s | [test](test_report_html) | [coverage](coverage_report_html)
diff
> Last update [##1234567](http://hoge.com) .. [##1234567](http://hoge.com)')

        plugin.report_summary
      end

      it 'success without test report' do
        build_mock = double('build')
        allow(build_mock).to receive(:report).and_return({ job_name: 'job', status: ':sunny:', duration: '10s' })
        allow(build_mock).to receive(:find_test_reports).and_return(nil)
        allow(build_mock).to receive(:find_coverage_report).and_return('coverage_report')
        allow(build_mock).to receive(:coverage_report_html).and_return(nil)

        context = { builds: [build_mock] }
        allow(plugin.head).to receive(:context).and_return(context)
        allow(plugin.head).to receive(:auth_get)
        allow(plugin.head).to receive(:sha_url).and_return('http://hoge.com')
        allow(plugin.head).to receive(:sha_short).and_return('#1234567')

        allow(plugin.base).to receive(:coverage_report_file).and_return('coverage_report')
        allow(plugin.base).to receive(:sha_url).and_return('http://hoge.com')
        allow(plugin.base).to receive(:sha_short).and_return('#1234567')

        code_coverage_mock = double('code_coverage')
        allow(code_coverage_mock).to receive(:parse).and_return('parsed')
        allow(code_coverage_mock).to receive(:summary_text_with_diff).and_return('coverage')

        allow(plugin).to receive(:create_coverage_diff).and_return('diff')

        allow(dangerfile).to receive(:code_coverage).and_return(code_coverage_mock)
        allow(plugin).to receive(:meta_all).and_return(nil)

        expect(dangerfile).to receive(:markdown).with('## Screwdriver Build Summary
Job | Status | Duration | Coverage
:--: | :--: | :--: | :--:
job | :sunny: | 10s | coverage
diff
> Last update [##1234567](http://hoge.com) .. [##1234567](http://hoge.com)')

        plugin.report_summary
      end

      it 'success without coverage report' do
        build_mock = double('build')
        allow(build_mock).to receive(:report).and_return({ job_name: 'job', status: ':sunny:', duration: '10s' })
        allow(build_mock).to receive(:find_test_reports).and_return(['test_report'])
        allow(build_mock).to receive(:find_coverage_report).and_return(nil)
        allow(build_mock).to receive(:test_report_html).and_return(nil)
        allow(build_mock).to receive(:coverage_report_html).and_return(nil)

        context = { builds: [build_mock] }
        allow(plugin.head).to receive(:context).and_return(context)
        allow(plugin.head).to receive(:auth_get)

        allow(plugin.base).to receive(:test_report_files).and_return(['test_report'])

        test_report_mock = double('test_report')
        allow(test_report_mock).to receive(:parse).and_return('parsed')
        allow(test_report_mock).to receive(:summary_text_with_diff).and_return('test')

        allow(dangerfile).to receive(:test_report).and_return(test_report_mock)
        allow(plugin).to receive(:meta_all).and_return(nil)

        expect(dangerfile).to receive(:markdown).with('## Screwdriver Build Summary
Job | Status | Duration | Test
:--: | :--: | :--: | :--:
job | :sunny: | 10s | test')

        plugin.report_summary        
      end
    end

    context 'create_coverage_diff' do
      it 'success' do
        head_result = { files: [{ file: 'hoge.rb', coverage: 0.10 }, { file: 'fuga.rb', coverage: 0.13 }] }
        base_result = { files: [{ file: 'hoge.rb', coverage: 0.12 }, { file: 'fuga.rb', coverage: 0.11 }] }

        expect(plugin.create_coverage_diff(head_result, base_result)).to eq('```diff
## Negative Impacted Files                                        Coverage        +/-
=====================================================================================
-  hoge.rb                                                           10.0%      -2.0%

## Positive Impacted Files                                        Coverage        +/-
=====================================================================================
+  fuga.rb                                                           13.0%      +2.0%
```
')
      end

      it 'return nil when head_result is nil' do
        base_result = { files: [{ file: 'hoge.rb', coverage: 0.12 }, { file: 'fuga.rb', coverage: 0.11 }] }

        expect(plugin.create_coverage_diff(nil, base_result)).to eq(nil)
      end

      it 'return nil when base_result is nil' do
        head_result = { files: [{ file: 'hoge.rb', coverage: 0.10 }, { file: 'fuga.rb', coverage: 0.13 }] }

        expect(plugin.create_coverage_diff(head_result, nil)).to eq(nil)
      end

      it 'files exist only on head or on base' do
        head_result = { files: [
                          { file: 'hoge.rb', coverage: 0.10 },
                          { file: 'fuga.rb', coverage: 0.13 },
                          { file: 'head.rb', coverage: 0.10 },
                        ] }

        base_result = { files: [
                          { file: 'hoge.rb', coverage: 0.12 },
                          { file: 'fuga.rb', coverage: 0.11 },
                          { file: 'base.rb', coverage: 0.10 },
                        ] }

        expect(plugin.create_coverage_diff(head_result, base_result)).to eq('```diff
## New Files                                                      Coverage        +/-
=====================================================================================
+  head.rb                                                           10.0%     +10.0%

## Negative Impacted Files                                        Coverage        +/-
=====================================================================================
-  base.rb                                                            0.0%     -10.0%
-  hoge.rb                                                           10.0%      -2.0%

## Positive Impacted Files                                        Coverage        +/-
=====================================================================================
+  fuga.rb                                                           13.0%      +2.0%
```
')
      end

      it 'more than 10 impacted files' do
        head_result = { files: [
                          { file: 'hoge0.rb', coverage: 0.10 },
                          { file: 'hoge1.rb', coverage: 0.11 },
                          { file: 'hoge2.rb', coverage: 0.12 },
                          { file: 'hoge3.rb', coverage: 0.13 },
                          { file: 'hoge4.rb', coverage: 0.14 },
                          { file: 'hoge5.rb', coverage: 0.15 },
                          { file: 'hoge6.rb', coverage: 0.16 },
                          { file: 'hoge7.rb', coverage: 0.17 },
                          { file: 'hoge8.rb', coverage: 0.18 },
                          { file: 'hoge9.rb', coverage: 0.19 },
                          { file: 'hoge10.rb', coverage: 0.20 },
                        ] }

        base_result = { files: [
                          { file: 'hoge0.rb', coverage: 0.21 },
                          { file: 'hoge1.rb', coverage: 0.21 },
                          { file: 'hoge2.rb', coverage: 0.21 },
                          { file: 'hoge3.rb', coverage: 0.21 },
                          { file: 'hoge4.rb', coverage: 0.21 },
                          { file: 'hoge5.rb', coverage: 0.21 },
                          { file: 'hoge6.rb', coverage: 0.21 },
                          { file: 'hoge7.rb', coverage: 0.21 },
                          { file: 'hoge8.rb', coverage: 0.21 },
                          { file: 'hoge9.rb', coverage: 0.21 },
                          { file: 'hoge10.rb', coverage: 0.21 },
                        ] }

        expect(plugin.create_coverage_diff(head_result, base_result)).to eq('```diff
## Negative Impacted Files                                        Coverage        +/-
=====================================================================================
-  hoge0.rb                                                          10.0%     -11.0%
-  hoge1.rb                                                          11.0%     -10.0%
-  hoge2.rb                                                          12.0%      -9.0%
-  hoge3.rb                                                          13.0%      -8.0%
-  hoge4.rb                                                          14.0%      -7.0%
-  hoge5.rb                                                          15.0%      -6.0%
-  hoge6.rb                                                          16.0%      -5.0%
-  hoge7.rb                                                          17.0%      -4.0%
-  hoge8.rb                                                          18.0%      -3.0%
-  hoge9.rb                                                          19.0%      -2.0%
##                                                       ... total impacted files: 11
```
')
      end

      it 'new files without tests' do
        head_result = { files: [{ file: 'hoge.rb', coverage: 0.0 }] }
        base_result = { files: [] }

        expect(plugin.create_coverage_diff(head_result, base_result)).to eq('```diff
## New Files                                                      Coverage        +/-
=====================================================================================
-  hoge.rb                                                            0.0%       0.0%
```
')
      end
    end

    context 'activate_chatops' do
      it 'successfully activate with correct comment' do
        ENV['DANGER_PR_COMMENT'] = '@ap-danger sd hoge'
        ENV['DANGER_EVENT'] = 'issue_comment'

        allow(plugin).to receive(:sd?).and_return(true)

        expect(plugin.head).to receive(:exec_job).with('hoge')
        plugin.activate_chatops

        ENV.delete('DANGER_PR_COMMENT')
        ENV.delete('DANGER_EVENT')
      end

      it 'not be activated for not screwdriver project' do
        ENV['DANGER_PR_COMMENT'] = '@ap-danger sd hoge'
        ENV['DANGER_EVENT'] = 'issue_comment'

        allow(plugin).to receive(:sd?).and_return(false)

        expect(plugin.head).not_to receive(:exec_job).with('hoge')
        plugin.activate_chatops

        ENV.delete('DANGER_PR_COMMENT')
        ENV.delete('DANGER_EVENT')
      end

      it 'not be activated for except issue_comment event' do
        ENV['DANGER_PR_COMMENT'] = '@ap-danger sd hoge'
        ENV['DANGER_EVENT'] = 'status'

        allow(plugin).to receive(:sd?).and_return(true)

        expect(plugin.head).not_to receive(:exec_job).with('hoge')
        plugin.activate_chatops

        ENV.delete('DANGER_PR_COMMENT')
        ENV.delete('DANGER_EVENT')
      end
    end

    context 'head' do
      it 'success' do
        expect(plugin.head).to be_truthy
      end

      it 'head is singletone' do
        expect(Danger::Screwdriver).to receive(:new).once.and_return(true)

        expect(plugin.head).to be_truthy
        expect(plugin.head).to be_truthy
      end
    end

    context 'base' do
      it 'success' do
        expect(plugin.base).to be_truthy
      end

      it 'base is singletone' do
        expect(Danger::Screwdriver).to receive(:new).once.and_return(true)

        expect(plugin.base).to be_truthy
        expect(plugin.base).to be_truthy
      end
    end
  end

  context 'sd?' do
    it 'success' do
      expect(plugin.sd?).to eq(true)
    end
  end

  context 'metas' do
    it 'success' do
      b0 = double('build_mock_0')
      b1 = double('build_mock_1')

      allow(b0).to receive(:detail).and_return({ 'meta' => { 'hoge' => 'ok' } })
      allow(b1).to receive(:detail).and_return({ 'meta' => { 'fuga' => 'ng' } })
      allow(plugin).to receive(:sd?).and_return(true)
      allow(plugin.head).to receive(:context).and_return({ builds: [b0, b1] })

      expect(plugin.metas).to eq([{ 'hoge' => 'ok' }, { 'fuga' => 'ng' }])
    end

    it 'not sd project' do
      allow(plugin).to receive(:sd?).and_return(false)

      expect(plugin.metas).to eq([])
    end

    it 'Build#detail returns nil' do
      b0 = double('build_mock_0')
      b1 = double('build_mock_1')

      allow(b0).to receive(:detail).and_return({ 'meta' => { 'hoge' => 'ok' } })
      allow(b1).to receive(:detail).and_return(nil)
      allow(plugin).to receive(:sd?).and_return(true)
      allow(plugin.head).to receive(:context).and_return({ builds: [b0, b1] })

      expect(plugin.metas).to eq([{ 'hoge' => 'ok' }])
    end
  end

  context 'artifact' do
    it 'success (path is String)'
    it 'success (path is Regexp)'
    it 'success (matches multiple artifacts but returns an artifact)'
    it 'Build#artifacts returns nil'
    it 'not Screwdriver project'
  end

  context 'artifact' do
    it 'success (path is String)'
    it 'success (path is Regexp)'
    it 'success (matches multiple artifacts and returns the artifacts)'
    it 'Build#artifacts returns nil'
    it 'not Screwdriver project'
  end

  context 'Screwdriver' do
    subject(:statuses_cd) { [{ context: 'Screwdriver', target_url: 'https://cd.screwdriver.corp.yahoo.co.jp/pipelines/1/builds/2' }] }
    subject(:statuses_next) { [{ context: 'Screwdriver', target_url: 'https://next.screwdriver.corp.yahoo.co.jp/pipelines/1/builds/2' }] }
    subject(:status_mock) { double('status') }

    before :each do
      api_mock = double('api')
      allow(api_mock).to receive(:combined_status).with('hoge/fuga', 'abc').and_return(status_mock)
      allow(api_mock).to receive(:combined_status).with('hoge/fuga', 'def').and_return(status_mock)
      allow(github).to receive(:api).and_return(api_mock)
    end

    context 'repo' do
      it 'success' do
        expect(plugin.head.repo).to eq('hoge/fuga')
        expect(plugin.base.repo).to eq('hoge/fuga')
      end
    end

    context 'pr_number' do
      it 'success' do
        expect(plugin.head.pr_number).to eq(1)
        expect(plugin.base.pr_number).to eq(1)
      end
    end

    context 'context' do
      it 'successfully parse for Screwdriver.cd for head' do
        allow(status_mock).to receive(:statuses).and_return(statuses_cd)

        expect(plugin.head.context[:next]).to eq(false)
        expect(plugin.head.context[:pipeline_id]).to eq('1')
        expect(plugin.head.context[:builds].size).to eq(1)
      end

      it 'successfully parse for Screwdriver.next for head' do
        allow(status_mock).to receive(:statuses).and_return(statuses_next)

        expect(plugin.head.context[:next]).to eq(true)
        expect(plugin.head.context[:pipeline_id]).to eq('1')
        expect(plugin.head.context[:builds].size).to eq(1)
      end

      it 'successfully parse for Screwdriver.cd for base' do
        allow(status_mock).to receive(:statuses).and_return(statuses_cd)

        expect(plugin.base.context[:next]).to eq(false)
        expect(plugin.base.context[:pipeline_id]).to eq('1')
        expect(plugin.base.context[:builds].size).to eq(1)
      end

      it 'successfully parse for Screwdriver.next for base' do
        allow(status_mock).to receive(:statuses).and_return(statuses_next)

        expect(plugin.base.context[:next]).to eq(true)
        expect(plugin.base.context[:pipeline_id]).to eq('1')
        expect(plugin.base.context[:builds].size).to eq(1)
      end
    end

    context 'jobs' do
      it 'successfully get jobs for head' do
        allow(status_mock).to receive(:statuses).and_return(statuses_cd)

        expect(plugin.head).to receive(:auth_get).with('https://hoge.com/pipelines/1/jobs').and_return('{}')
        expect(plugin.head).to receive(:endpoint).and_return('https://hoge.com')

        plugin.head.jobs
      end
    end

    context 'coverage_report_file' do
      it 'success' do
        mock_build = double('build')
        mock_context = { builds: [mock_build] }

        allow(mock_build).to receive(:find_coverage_report).and_return('hoge')
        allow(plugin.head).to receive(:context).and_return(mock_context)

        expect(plugin.head).to receive(:auth_get).with('hoge')

        plugin.head.coverage_report_file
      end

      it 'success (includes nil build)' do
        mock_build0 = double('build')
        mock_build1 = double('build')
        mock_context = { builds: [mock_build0, mock_build1] }

        allow(mock_build0).to receive(:find_coverage_report).and_return(nil)
        allow(mock_build1).to receive(:find_coverage_report).and_return('hoge')
        allow(plugin.head).to receive(:context).and_return(mock_context)

        expect(plugin.head).to receive(:auth_get).with('hoge')

        plugin.head.coverage_report_file
      end

      it 'success (not report found)' do
        mock_build0 = double('build')
        mock_build1 = double('build')
        mock_context = { builds: [mock_build0, mock_build1] }

        allow(mock_build0).to receive(:find_coverage_report).and_return(nil)
        allow(mock_build1).to receive(:find_coverage_report).and_return(nil)
        allow(plugin.head).to receive(:context).and_return(mock_context)

        expect(plugin.head).not_to receive(:auth_get).with('hoge')
        expect(plugin.head.coverage_report_file).to eq(nil)
      end
    end

    context 'test_report_files' do
      it 'success' do
        mock_build = double('build')
        mock_context = { builds: [mock_build] }

        allow(mock_build).to receive(:find_test_reports).and_return(['hoge'])
        allow(plugin.head).to receive(:context).and_return(mock_context)

        expect(plugin.head).to receive(:auth_get).with('hoge')

        plugin.head.test_report_files
      end

      it 'success (includes nil build)' do
        mock_build0 = double('build')
        mock_build1 = double('build')
        mock_context = { builds: [mock_build0, mock_build1] }

        allow(mock_build0).to receive(:find_test_reports).and_return(nil)
        allow(mock_build1).to receive(:find_test_reports).and_return(['hoge'])
        allow(plugin.head).to receive(:context).and_return(mock_context)

        expect(plugin.head).to receive(:auth_get).with('hoge')

        plugin.head.test_report_files
      end

      it 'success (not report found)' do
        mock_build0 = double('build')
        mock_build1 = double('build')
        mock_context = { builds: [mock_build0, mock_build1] }

        allow(mock_build0).to receive(:find_test_reports).and_return(nil)
        allow(mock_build1).to receive(:find_test_reports).and_return(nil)
        allow(plugin.head).to receive(:context).and_return(mock_context)

        expect(plugin.head).not_to receive(:auth_get).with('hoge')
        expect(plugin.head.test_report_files).to eq(nil)
      end
    end

    context 'endpoint' do
      it 'cd for head' do
        allow(status_mock).to receive(:statuses).and_return(statuses_cd)
        expect(plugin.head.endpoint).to eq('https://api-cd.screwdriver.corp.yahoo.co.jp/v4')
      end

      it 'next for head' do
        allow(status_mock).to receive(:statuses).and_return(statuses_next)
        expect(plugin.head.endpoint).to eq('https://api-next.screwdriver.corp.yahoo.co.jp/v4')
      end

      it 'cd for base' do
        allow(status_mock).to receive(:statuses).and_return(statuses_cd)
        expect(plugin.base.endpoint).to eq('https://api-cd.screwdriver.corp.yahoo.co.jp/v4')
      end

      it 'next for base' do
        allow(status_mock).to receive(:statuses).and_return(statuses_next)
        expect(plugin.base.endpoint).to eq('https://api-next.screwdriver.corp.yahoo.co.jp/v4')
      end
    end

    context 'webui' do
      it 'cd for head' do
        allow(status_mock).to receive(:statuses).and_return(statuses_cd)
        expect(plugin.head.webui).to eq('https://cd.screwdriver.corp.yahoo.co.jp')
      end

      it 'next for head' do
        allow(status_mock).to receive(:statuses).and_return(statuses_next)
        expect(plugin.head.webui).to eq('https://next.screwdriver.corp.yahoo.co.jp')
      end

      it 'cd for base' do
        allow(status_mock).to receive(:statuses).and_return(statuses_cd)
        expect(plugin.base.webui).to eq('https://cd.screwdriver.corp.yahoo.co.jp')
      end

      it 'next for base' do
        allow(status_mock).to receive(:statuses).and_return(statuses_next)
        expect(plugin.base.webui).to eq('https://next.screwdriver.corp.yahoo.co.jp')
      end
    end

    context 'auth_get' do
      it 'success' do
        allow(status_mock).to receive(:statuses).and_return(statuses_cd)

        expect(plugin.head).to receive(:auth_request).with(Net::HTTP::Get, 'http://cd.com', nil, false)
        expect(plugin.head.auth_get('http://cd.com'))
      end

      it 'return nil when ignoring errors'
    end

    context 'auth_post' do
      it 'success' do
        allow(status_mock).to receive(:statuses).and_return(statuses_cd)

        expect(plugin.head).to receive(:auth_request).with(Net::HTTP::Post, 'http://cd.com', 'body', false)
        expect(plugin.head.auth_post('http://cd.com', 'body'))
      end

      it 'return nil when ignoring errors'
    end

    context 'auth_request' do
      it 'skip due to the complexity of network stubs'
      it 'return nil when ignoring errors'
    end

    context 'jwt_token' do
      it 'success with env var' do
        ENV['SD_JWT_TOKEN'] = 'jwt'

        expect(plugin.head.jwt_token).to eq('jwt')

        ENV.delete('SD_JWT_TOKEN')
      end

      it 'success' do
        expect(Net::HTTP).to receive(:get).and_return('{"token": "jwt"}')
        expect(plugin.head).to receive(:context).and_return({ next: false })
        expect(plugin.head.jwt_token).to eq('jwt')
      end

      it 'cached' do
        expect(Net::HTTP).to receive(:get).once.and_return('{"token": "jwt"}')
        expect(plugin.head).to receive(:context).once.and_return({ next: false })
        expect(plugin.head.jwt_token).to eq('jwt')
        expect(plugin.head.jwt_token).to eq('jwt')
      end
    end

    context 'exec_job' do
      it 'success' do
        jobs = [{ 'name' => 'PR-1:hoge' }]
        allow(plugin.head).to receive(:context).and_return({ pipeline_id: '1' })
        allow(plugin.head).to receive(:jobs).and_return(jobs)

        expect(plugin.head).to receive(:auth_post)

        api_mock = double('api')
        expect(api_mock).to receive(:add_comment).with(plugin.head.repo, plugin.head.pr_number, '**hoge** を開始しました')
        expect(github).to receive(:api).and_return(api_mock)

        plugin.head.exec_job('hoge')
      end

      it 'job not found' do
        jobs = [{ 'name' => 'PR-1:hoge' }]
        allow(plugin.head).to receive(:context).and_return({ pipeline_id: '1' })
        allow(plugin.head).to receive(:jobs).and_return(jobs)

        api_mock = double('api')
        expect(api_mock).to receive(:add_comment).with(plugin.head.repo, plugin.head.pr_number, "**hoge2** が見つかりませんでした。\n\n利用可能なjobのリストです。\nhoge\n")
        expect(github).to receive(:api).and_return(api_mock)

        plugin.head.exec_job('hoge2')
      end
    end
  end

  context 'Build' do
    subject(:build) { Danger::Build.new(plugin.head, "id", "state") }

    context 'report' do
      it 'success' do
        expect(build).to receive(:job_name).and_return('job')
        expect(build).to receive(:status_emoji).and_return(':sunny:')
        expect(build).to receive(:duration).and_return('10s')
        expect(build).to receive(:log_link).and_return('http://hoge.com')
        expect(build.report).to eq({ job_name: '[job](http://hoge.com)', status: ':sunny:', duration: '10s'})
      end
    end

    context 'detail' do
      it 'success' do
        allow(plugin.head).to receive(:endpoint).and_return('http://hoge.com')
        allow(plugin.head).to receive(:auth_get).and_return('{"spec": "ok"}')

        expect(build.detail).to eq({ 'spec' => 'ok' })
      end

      it 'auth_get returns nil' do
        allow(plugin.head).to receive(:endpoint).and_return('http://hoge.com')
        allow(plugin.head).to receive(:auth_get).and_return(nil)

        expect(build.detail).to be_nil
      end
    end

    context 'job' do
      it 'success' do
        allow(plugin.head).to receive(:endpoint).and_return('http://hoge.com')
        allow(plugin.head).to receive(:auth_get).with('http://hoge.com/builds/id', true).and_return('{"jobId": "3"}')
        allow(plugin.head).to receive(:auth_get).with('http://hoge.com/jobs/3').and_return('{"spec": "ok"}')

        expect(build.job).to eq({ 'spec' => 'ok' })
      end

      it 'detail is nil' do
        allow(plugin.head).to receive(:endpoint).and_return('http://hoge.com')
        allow(plugin.head).to receive(:auth_get).with('http://hoge.com/builds/id', true).and_return(nil)

        expect(build.job).to be_nil
      end
    end

    context 'artifacts' do
      it 'success' do
        artifacts = "./hoge.txt\n./fuga.txt\n"
        allow(plugin.head).to receive(:auth_get).and_return(artifacts)
        allow(plugin.head).to receive(:endpoint).and_return('http://hoge.com')

        expect(build.artifacts).to eq(['http://hoge.com/builds/id/artifacts/hoge.txt', 'http://hoge.com/builds/id/artifacts/fuga.txt'])
      end
    end

    context 'job_name' do
      it 'success' do
        allow(build).to receive(:job).and_return({ 'name' => 'PR-5:hoge' })

        expect(build.job_name).to eq('hoge')
      end

      it 'job is nil' do
        allow(build).to receive(:job).and_return(nil)

        expect(build.job_name).to eq('unknown')
      end
    end

    context 'duration' do
      it 'finished' do
        allow(build).to receive(:finished?).and_return(true)
        allow(build).to receive(:duration_pretty).and_return('ok')
        allow(build).to receive(:detail).and_return({ 'startTime' => Time.now.to_s, 'endTime' => Time.now.to_s })

        expect(build.duration).to eq('ok')
      end

      it 'not finished' do
        allow(build).to receive(:finished?).and_return(false)

        expect(build.duration).to eq('-')
      end

      it 'detail[startTime] is nil' do
        allow(build).to receive(:finished?).and_return(true)
        allow(build).to receive(:detail).and_return({ 'endTime' => Time.now.to_s })

        expect(build.duration).to eq('-')
      end

      it 'detail[endTime] is nil' do
        allow(build).to receive(:finished?).and_return(true)
        allow(build).to receive(:detail).and_return({ 'startTime' => Time.now.to_s })

        expect(build.duration).to eq('-')
      end
    end

    context 'duration_pretty' do
      it 'seconds' do
        expect(build.duration_pretty(10)).to eq('10s')
      end

      it 'minutes' do
        expect(build.duration_pretty(70)).to eq('1m 10s')
      end

      it 'hours' do
        expect(build.duration_pretty(3670)).to eq('1h 1m 10s')
      end
    end

    context 'status_emoji' do
      it 'QUEUED' do
        allow(build).to receive(:detail).and_return({ 'status' => 'QUEUED' })
        expect(build.status_emoji).to eq(':zzz:')
      end

      it 'RUNNING' do
        allow(build).to receive(:detail).and_return({ 'status' => 'RUNNING' })
        expect(build.status_emoji).to eq(':running:')
      end

      it 'SUCCESS' do
        allow(build).to receive(:detail).and_return({ 'status' => 'SUCCESS' })
        expect(build.status_emoji).to eq(':white_check_mark:')
      end

      it 'ABORTED' do
        allow(build).to receive(:detail).and_return({ 'status' => 'ABORTED' })
        expect(build.status_emoji).to eq(':no_entry_sign:')
      end

      it 'FAILURE' do
        allow(build).to receive(:detail).and_return({ 'status' => 'FAILURE' })
        expect(build.status_emoji).to eq(':x:')
      end

      it 'unknown' do
        allow(build).to receive(:detail).and_return({ 'status' => 'hoge' })
        expect(build.status_emoji).to eq(':question:')
      end

      it 'detail is nil' do
        allow(build).to receive(:detail).and_return(nil)
        expect(build.status_emoji).to eq('-')
      end
    end

    context 'log_link' do
      it 'success' do
        allow(plugin.head).to receive(:webui).and_return('http://hoge.com')
        allow(plugin.head).to receive(:context).and_return({ pipeline_id: 1 })

        expect(build.log_link).to eq('http://hoge.com/pipelines/1/builds/id')
      end
    end

    context 'finished?' do
      it 'QUEUED' do
        allow(build).to receive(:detail).and_return({ 'status' => 'QUEUED' })
        expect(build.finished?).to eq(false)
      end

      it 'RUNNING' do
        allow(build).to receive(:detail).and_return({ 'status' => 'RUNNING' })
        expect(build.finished?).to eq(false)
      end

      it 'finished' do
        allow(build).to receive(:detail).and_return({ 'status' => 'SUCCESS' })
        expect(build.finished?).to eq(true)
      end

      it 'detail is nil' do
        allow(build).to receive(:detail).and_return(nil)
        expect(build.finished?).to eq(false)
      end
    end
  end

  context 'DiffTable' do

    subject(:diff_table) { Danger::DiffTable.new }

    it 'header' do
      expect(diff_table.header('title', 'head', 'diff').create).to eq('```diff
## title                                                              head       diff
=====================================================================================
```
')
    end

    it 'empty' do
      expect(diff_table.empty.create).to eq('```diff

```
')
    end

    context 'diff' do
      it 'positive' do
        expect(diff_table.diff('title', 10.0, 2.0, '%').create).to eq('```diff
+  title                                                             10.0%      +2.0%
```
')
      end

      it 'negative' do
        expect(diff_table.diff('title', 10.0, -2.0, '%').create).to eq('```diff
-  title                                                             10.0%      -2.0%
```
')
      end

      it 'equal' do
        expect(diff_table.diff('title', 10.0, 0.0, '%').create).to eq('```diff
   title                                                             10.0%       0.0%
```
')
      end
    end

    context 'row' do
      it 'success' do
        expect(diff_table.row('title', 'head', 'diff')).to eq('title                                                              head       diff')
      end

      it 'title is too long' do
        title = 't' * 100
        expect(diff_table.row(title, 'head', 'diff')).to eq('...ttttttttttttttttttttttttttttttttttttttttttttttttttttttttt       head       diff')
      end

      it 'head is too long' do
        head = 'h' * 100
        expect(diff_table.row('title', head, 'diff')).to eq('title                                                        ...hhhhhhh       diff')
      end

      it 'diff is too long' do
        diff = 'd' * 100
        expect(diff_table.row('title', 'head', diff)).to eq('title                                                              head ...ddddddd')
      end

      it 'too long' do
        title = 't' * 100
        head = 'h' * 100
        diff = 'd' * 100

        expect(diff_table.row(title, head, diff)).to eq('...ttttttttttttttttttttttttttttttttttttttttttttttttttttttttt ...hhhhhhh ...ddddddd')
      end
    end
  end
end
