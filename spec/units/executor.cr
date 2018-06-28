def mock_executable : HostedDanger::Executable
  {
    action:      "action",
    event:       "event",
    html_url:    "https://ghe.corp.yahoo.co.jp/hosted-danger/hosted-danger",
    pr_number:   1,
    sha:         "abcdefghijklmnop",
    base_branch: "master",
    raw_payload: "raw_payload",
    env:         {} of String => String,
  }
end

describe HostedDanger::Executor do
  it "with_dragon_envs" do
    setup_envs_prod do
      executable = mock_executable
      executable[:env]["hoge"] = "test"

      executor = HostedDanger::Executor.new(executable)
      executor.env["DRAGON_ACCESS_KEY"]?.should be_nil
      executor.env["DRAGON_SECRET_ACCESS_KEY"]?.should be_nil

      executor.with_dragon_envs do
        executor.env["DRAGON_ACCESS_KEY"].should eq("dragon_key")
        executor.env["DRAGON_SECRET_ACCESS_KEY"].should eq("dragon_secret_key")
        executor.env["hoge"].should eq("test")
      end

      executor.env["DRAGON_ACCESS_KEY"]?.should be_nil
      executor.env["DRAGON_SECRET_ACCESS_KEY"]?.should be_nil
    end
  end

  it "dir of Executor is always same" do
    executor = HostedDanger::Executor.new(mock_executable)
    dir = executor.dir
    executor.dir.should eq(dir)
  end

  it "org_dir of Executor is always same" do
    executor = HostedDanger::Executor.new(mock_executable)
    org_dir = executor.org_dir
    executor.org_dir.should eq(org_dir)
  end
end
