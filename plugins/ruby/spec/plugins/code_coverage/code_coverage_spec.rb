require "spec_helper"

describe Danger::DangerCodeCoverage do
  CODE_COVERAGE_FIXTURES = __dir__  + "/fixtures"

  subject(:plugin) { Danger::DangerCodeCoverage.new(nil) }

  it "parse cobertura" do
    r = plugin.parse(File.read("#{CODE_COVERAGE_FIXTURES}/cobertura.xml"))

    expect(r[:line_rate]).to eq(1.0)
    expect(r[:files][0][:file]).to eq("cc.js")
    expect(r[:files][0][:coverage]).to eq(1.0)
  end

  it "parse cobetura without 'classes' node" do
    r = plugin.parse(File.read("#{CODE_COVERAGE_FIXTURES}/cobertura2.xml"))

    expect(r[:line_rate]).to eq(0.6)
    expect(r[:files][0][:file]).to eq("index.js")
    expect(r[:files][0][:coverage]).to eq(0.6)
  end

  it "parse jacoco" do
    r = plugin.parse(File.read("#{CODE_COVERAGE_FIXTURES}/jacoco.xml"))

    expect(r[:line_rate]).to eq(0.07142857142857142)
    expect(r[:files][0][:file]).to eq("jp/co/yahoo/corp/approduce/dev/androidv4sample/MainActivity")
    expect(r[:files][0][:coverage]).to eq(0.2857142857142857)
    expect(r[:files][1][:file]).to eq("jp/co/yahoo/corp/approduce/dev/androidv4sample/NextActivity")
    expect(r[:files][1][:coverage]).to eq(0.0)
  end

  context 'summary_text' do
    it 'success' do
      result = { line_rate: 0.1 }

      expect(plugin.summary_text(result)).to eq('10%')
    end
  end

  context 'summary_text_with_diff' do
    it 'success (0 diff)' do
      head_result = { line_rate: 0.1 }
      base_result = { line_rate: 0.1 }

      allow(plugin).to receive(:summary_text).and_return('hoge')

      expect(plugin.summary_text_with_diff(head_result, base_result)).to eq('hoge (±0%)')
    end

    it 'success (positive)' do
      head_result = { line_rate: 0.2 }
      base_result = { line_rate: 0.1 }

      allow(plugin).to receive(:summary_text).and_return('hoge')

      expect(plugin.summary_text_with_diff(head_result, base_result)).to eq('hoge (+10%)')
    end

    it 'success (negative)' do
      head_result = { line_rate: 0.1 }
      base_result = { line_rate: 0.2 }

      allow(plugin).to receive(:summary_text).and_return('hoge')

      expect(plugin.summary_text_with_diff(head_result, base_result)).to eq('hoge (-10%)')
    end
  end
end
