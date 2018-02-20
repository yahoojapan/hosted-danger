include HostedDanger::Executor

describe HostedDanger::Executor do
  sample_root = File.expand_path("../../samples", __FILE__)

  it "use ruby if Dangerfile exists" do
    use_ruby?("#{sample_root}/dangerfile").should eq(true)
  end

  it "use js if dangerfile.js exists" do
    use_ruby?("#{sample_root}/dangerfile_js").should eq(false)
  end

  it "use js if dangerfile.ts exists" do
    use_ruby?("#{sample_root}/dangerfile_ts").should eq(false)
  end

  it "use ruby if any danger dsls are not found" do
    use_ruby?("#{sample_root}/empty").should eq(true)
  end

  it "use bundler if Gemfile contains danger" do
    use_bundler?("#{sample_root}/with_gemfile_with_danger").should eq(true)
  end

  it "don't use bundler if Gemfile doesn't contain danger" do
    use_bundler?("#{sample_root}/with_gemfile_without_danger").should eq(false)
  end

  it "don't use bundler if Gemfile doesn't exist" do
    use_bundler?("#{sample_root}/empty").should eq(false)
  end

  it "use yarn if yarn.lock contains danger" do
    use_yarn?("#{sample_root}/yarn_with_danger").should eq(true)
  end

  it "don't use yarn if yarn.lock doesn't contain danger" do
    use_yarn?("#{sample_root}/yarn_without_danger").should eq(false)
  end

  it "don't use yarn if yarn.lock doesn't exist" do
    use_yarn?("#{sample_root}/empty").should eq(false)
  end

  it "use npm if package-lock.json contains danger" do
    use_npm?("#{sample_root}/npm_with_danger").should eq(true)
  end

  it "don't use npm if package-lock.json doesn't contain danger" do
    use_npm?("#{sample_root}/npm_without_danger").should eq(false)
  end

  it "don't use npm if package-lock.json doesn't exist" do
    use_npm?("#{sample_root}/empty").should eq(false)
  end
end
