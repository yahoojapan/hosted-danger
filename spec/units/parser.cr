include HostedDanger::Parser

describe HostedDanger::Parser do
  html_url_url = "https://github.com/yahoojapan/hosted-danger"
  html_url_ssh = "git@github.com:yahoojapan/hosted-danger"
  html_url_scm = "https://SCM_USERNAME:SCM_ACCESS_TOKEN@github.com/yahoojapan/hosted-danger"

  it "git_host_from_html_url" do
    git_host_from_html_url(html_url_url).should eq("github.com")
    git_host_from_html_url(html_url_ssh).should eq("github.com")
    git_host_from_html_url(html_url_scm).should eq("github.com")
  end

  it "access_token_from_git_host" do
    setup_envs do
      access_token_from_git_host("github.com").should eq("dummy_token")
      access_token_from_git_host("github2.com").should eq("dummy_token_two")
    end
  end

  it "org_repo_from_html_url" do
    org_repo_from_html_url(html_url_url).should eq(["yahoojapan", "hosted-danger"])
    org_repo_from_html_url(html_url_ssh).should eq(["yahoojapan", "hosted-danger"])
    org_repo_from_html_url(html_url_scm).should eq(["yahoojapan", "hosted-danger"])
  end

  it "remote_from_html_url" do
    remote_from_html_url(html_url_url, "abc").should eq("https://ap-danger:abc@github.com/yahoojapan/hosted-danger")
  end
end
