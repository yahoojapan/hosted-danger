describe HostedDanger::ConfigWrapper do
  sample_root = File.expand_path("../../samples", __FILE__)

  it "use ruby if any danger dsls are not found" do
    config_wrapper = HostedDanger::ConfigWrapper.new("#{sample_root}/empty")
    config_wrapper.get_lang.should eq("ruby")
  end

  it "use ruby if Dangerfile.hosted exists" do
    config_wrapper = HostedDanger::ConfigWrapper.new("#{sample_root}/dangerfile")
    config_wrapper.get_lang.should eq("ruby")
  end

  it "use ruby if Dangerfile.hosted.rb exists" do
    config_wrapper = HostedDanger::ConfigWrapper.new("#{sample_root}/dangerfile_rb")
    config_wrapper.get_lang.should eq("ruby")
  end

  it "use js if dangerfile.js exists" do
    config_wrapper = HostedDanger::ConfigWrapper.new("#{sample_root}/dangerfile_js")
    config_wrapper.get_lang.should eq("js")
  end

  it "use js if dangerfile.ts exists" do
    config_wrapper = HostedDanger::ConfigWrapper.new("#{sample_root}/dangerfile_ts")
    config_wrapper.get_lang.should eq("js")
  end

  it "use Dangerfile.hosted by default" do
    config_wrapper = HostedDanger::ConfigWrapper.new("#{sample_root}/empty")
    config_wrapper.dangerfile.should eq("Dangerfile.hosted")
  end

  it "use Dangerfile.hosted if the file exists" do
    config_wrapper = HostedDanger::ConfigWrapper.new("#{sample_root}/dangerfile")
    config_wrapper.dangerfile.should eq("Dangerfile.hosted")
  end

  it "use Dangerfile.hosted.rb if the file exists" do
    config_wrapper = HostedDanger::ConfigWrapper.new("#{sample_root}/dangerfile_rb")
    config_wrapper.dangerfile.should eq("Dangerfile.hosted.rb")
  end

  it "use dangerfile.hosted.js if the file exists" do
    config_wrapper = HostedDanger::ConfigWrapper.new("#{sample_root}/dangerfile_js")
    config_wrapper.dangerfile.should eq("dangerfile.hosted.js")
  end

  it "use dangerfile.hosted.ts if the file exists" do
    config_wrapper = HostedDanger::ConfigWrapper.new("#{sample_root}/dangerfile_ts")
    config_wrapper.dangerfile.should eq("dangerfile.hosted.ts")
  end

  it "use bundler if Gemfile contains danger" do
    config_wrapper = HostedDanger::ConfigWrapper.new("#{sample_root}/with_gemfile_with_danger")
    config_wrapper.use_bundler?.should be_true
  end

  it "don't use bundler if Gemfile doesn't contain danger" do
    config_wrapper = HostedDanger::ConfigWrapper.new("#{sample_root}/with_gemfile_without_danger")
    config_wrapper.use_bundler?.should be_false
  end

  it "don't use bundler if Gemfile doesn't exist" do
    config_wrapper = HostedDanger::ConfigWrapper.new("#{sample_root}/empty")
    config_wrapper.use_bundler?.should be_false
  end

  it "use yarn if yarn.lock contains danger" do
    config_wrapper = HostedDanger::ConfigWrapper.new("#{sample_root}/yarn_with_danger")
    config_wrapper.use_yarn?.should be_true
  end

  it "don't use yarn if yarn.lock doesn't contain danger" do
    config_wrapper = HostedDanger::ConfigWrapper.new("#{sample_root}/yarn_without_danger")
    config_wrapper.use_yarn?.should be_false
  end

  it "don't use yarn if yarn.lock doesn't exist" do
    config_wrapper = HostedDanger::ConfigWrapper.new("#{sample_root}/empty")
    config_wrapper.use_yarn?.should be_false
  end

  it "use npm if package-lock.json contains danger" do
    config_wrapper = HostedDanger::ConfigWrapper.new("#{sample_root}/npm_with_danger")
    config_wrapper.use_npm?.should be_true
  end

  it "don't use npm if package-lock.json doesn't contain danger" do
    config_wrapper = HostedDanger::ConfigWrapper.new("#{sample_root}/npm_without_danger")
    config_wrapper.use_npm?.should be_false
  end

  it "don't use npm if package-lock.json doesn't exist" do
    config_wrapper = HostedDanger::ConfigWrapper.new("#{sample_root}/empty")
    config_wrapper.use_npm?.should be_false
  end

  it "get every events if the configuration is not defined" do
    config_wrapper = HostedDanger::ConfigWrapper.new("#{sample_root}/empty")

    events = config_wrapper.events
    events.size.should eq(5)
    events.includes?("pull_request").should be_true
    events.includes?("pull_request_review").should be_true
    events.includes?("pull_request_review_comment").should be_true
    events.includes?("issue_comment").should be_true
    events.includes?("issues").should be_true
    events.includes?("status").should be_false
  end
end
