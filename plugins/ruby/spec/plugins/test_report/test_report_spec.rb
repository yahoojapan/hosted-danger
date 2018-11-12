require "spec_helper"

describe Danger::DangerTestReport do
  TEST_REPORT_FIXTURES = __dir__ + "/fixtures"

  subject(:plugin) { Danger::DangerTestReport.new(nil) }

  it "parse danger-junit-fail" do
    r = plugin.parse(File.read("#{TEST_REPORT_FIXTURES}/danger-junit-fail.xml"))
    expect(r[:tests]).to eq(48)
    expect(r[:passes]).to eq(46)
    expect(r[:skipped]).to eq(1)
    expect(r[:failures]).to eq(1)
    expect(r[:errors]).to eq(0)
  end

  it "parse selenium" do
    r = plugin.parse(File.read("#{TEST_REPORT_FIXTURES}/selenium.xml"))
    expect(r[:tests]).to eq(1)
    expect(r[:passes]).to eq(0)
    expect(r[:skipped]).to eq(0)
    expect(r[:failures]).to eq(1)
    expect(r[:errors]).to eq(0)
  end

  it "parse eigen_fail" do
    r = plugin.parse(File.read("#{TEST_REPORT_FIXTURES}/eigen_fail.xml"))
    expect(r[:tests]).to eq(1111)
    expect(r[:passes]).to eq(1109)
    expect(r[:skipped]).to eq(0)
    expect(r[:failures]).to eq(2)
    expect(r[:errors]).to eq(0)
  end

  it "parse rspec_fail" do
    r = plugin.parse(File.read("#{TEST_REPORT_FIXTURES}/rspec_fail.xml"))
    expect(r[:tests]).to eq(198)
    expect(r[:passes]).to eq(190)
    expect(r[:skipped]).to eq(7)
    expect(r[:failures]).to eq(1)
    expect(r[:errors]).to eq(0)
  end

  it "parse fastlane_trainer" do
    r = plugin.parse(File.read("#{TEST_REPORT_FIXTURES}/fastlane_trainer.xml"))
    expect(r[:tests]).to eq(2)
    expect(r[:passes]).to eq(1)
    expect(r[:skipped]).to eq(0)
    expect(r[:failures]).to eq(1)
    expect(r[:errors]).to eq(0)
  end

  it "parse multiple junit files" do
    file0 = File.read("#{TEST_REPORT_FIXTURES}/danger-junit-fail.xml")
    file1 = File.read("#{TEST_REPORT_FIXTURES}/danger-junit-fail.xml")
    file2 = File.read("#{TEST_REPORT_FIXTURES}/danger-junit-fail.xml")

    r = plugin.parse([file0, file1, file2])
    expect(r[:tests]).to eq(48 * 3)
    expect(r[:passes]).to eq(46 * 3)
    expect(r[:skipped]).to eq(1 * 3)
    expect(r[:failures]).to eq(1 * 3)
    expect(r[:errors]).to eq(0 * 3)
  end

  context 'summary_text' do
    it 'success (test: 4, failures: 1, errors: 1, skipped: 1)' do
      result = { tests: 3, failures: 1, errors: 1, skipped: 1 }

      expect(plugin.summary_text(result)).to eq(':umbrella: **3 tests, 2 failures, 1 skipped.**')
    end

    it 'success (test: 1, failures: 0, errors: 0, skipped: 0)' do
      result = { tests: 1, failures: 0, errors: 0, skipped: 0 }

      expect(plugin.summary_text(result)).to eq(':sunny: **1 test, 0 failures.**')
    end

    it 'success (test: 1, failures: 0, errors: 0, skipped: 1)' do
      result = { tests: 1, failures: 0, errors: 0, skipped: 1 }

      expect(plugin.summary_text(result)).to eq(':cloud: **1 test, 0 failures, 1 skipped.**')
    end
  end

  context 'summary_text_with_diff' do
    it 'success (0 diff)' do
      head_result = {tests: 1}
      base_result = {tests: 1}

      allow(plugin).to receive(:summary_text).and_return('hoge')

      expect(plugin.summary_text_with_diff(head_result, base_result)).to eq('hoge (±0)')
    end

    it 'succeeds (positive)' do
      head_result = {tests: 1}
      base_result = {tests: 0}

      allow(plugin).to receive(:summary_text).and_return('hoge')

      expect(plugin.summary_text_with_diff(head_result, base_result)).to eq('hoge (+1)')
    end

    it 'succeeds (negative)' do
      head_result = {tests: 0}
      base_result = {tests: 1}

      allow(plugin).to receive(:summary_text).and_return('hoge')

      expect(plugin.summary_text_with_diff(head_result, base_result)).to eq('hoge (-1)')
    end

    it 'return summary_text when base_result is nil' do
      expect(plugin).to receive(:summary_text)

      plugin.summary_text_with_diff('hoge', nil)
    end
  end
end
