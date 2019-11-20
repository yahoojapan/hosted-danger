def mock_executable : HostedDanger::Executable
  {
    action:      "action",
    event:       "event",
    html_url:    "https://github.com/yahoojapan/hosted-danger",
    pr_number:   1,
    sha:         "abcdefghijklmnop",
    base_sha:    "klmnopqrstuvwxyz",
    head_label:  "myorg:fugauga",
    base_label:  "myorg:hogehoge",
    raw_payload: "raw_payload",
    env:         {} of String => String,
  }
end

describe HostedDanger::Executor do
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
