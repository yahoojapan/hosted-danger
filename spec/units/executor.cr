include HostedDanger::Executor

describe HostedDanger::Executor do

  sample_root = File.expand_path("../../samples", __FILE__)

  it "use bundler if Gemfile contains danger" do
    use_bundler?("#{sample_root}/with_gemfile_with_danger").should eq(true)
  end

  it "don't use bundler if Gemfile doesn't contain danger" do
    use_bundler?("#{sample_root}/with_gemfile_without_danger").should eq(false)
  end

  it "don't use bundler if Gemfile doen't exist" do
    use_bundler?("#{sample_root}/without_gemfile").should eq(false)
  end
end
