describe HostedDanger::Config do
  sample_root = File.expand_path("../../samples", __FILE__)

  it "parsing danger.yaml successfully" do
    config = HostedDanger::Config.parse("#{sample_root}/config/danger.yaml").not_nil!
    config.lang.not_nil!.should eq("ruby")
    config.dangerfile.not_nil!.should eq("Dangerfile.hosted")
    config.events.not_nil!.includes?("pull_request").should be_true
    config.events.not_nil!.includes?("issue_comment").should be_true
    config.events.not_nil!.includes?("status").should be_false
    config.bundler.not_nil!.should be_true
    config.npm.not_nil!.should be_true
    config.yarn.not_nil!.should be_true
  end

  it "return nil except specified dangerfile" do
    config = HostedDanger::Config.parse("#{sample_root}/config/only_dangerfile.yaml").not_nil!
    config.lang.should be_nil
    config.dangerfile.not_nil!.should eq("dangerfile.js.2")
    config.events.should be_nil
    config.bundler.should be_nil
    config.npm.should be_nil
    config.yarn.should be_nil
  end

  it "return nil if config not exists" do
    config = HostedDanger::Config.parse("#{sample_root}/empty/danger.yaml")
    config.should be_nil
  end
end
