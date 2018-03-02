require "../utils/ready_env_json"

include HostedDanger::Parser

describe HostedDanger::Parser do
  html_url_ghe = "https://ghe.corp.yahoo.co.jp/hosted-danger/docs"
  html_url_partner = "https://partner.git.corp.yahoo.co.jp/hosted-danger/docs"
  html_url_git = "https://git.corp.yahoo.co.jp/hosted-danger/docs"

  ghe = "ghe.corp.yahoo.co.jp"
  partner = "partner.git.corp.yahoo.co.jp"
  git = "git.corp.yahoo.co.jp"

  it "git_host_from_html_url" do
    git_host_from_html_url(html_url_ghe).should eq(ghe)
    git_host_from_html_url(html_url_partner).should eq(partner)
    git_host_from_html_url(html_url_git).should eq(git)
  end

  it "access_token_from_git_host" do
    ready_env_json

    access_token_from_git_host(ghe).should eq("dummy_ghe")
    access_token_from_git_host(partner).should eq("dummy_partner")
    access_token_from_git_host(git).should eq("dummy_git")
  end

  it "org_repo_from_html_url" do
    org_repo_from_html_url(html_url_ghe).should eq(["hosted-danger", "docs"])
    org_repo_from_html_url(html_url_partner).should eq(["hosted-danger", "docs"])
    org_repo_from_html_url(html_url_git).should eq(["hosted-danger", "docs"])
  end

  it "remote_from_html_url" do
    remote_from_html_url(html_url_ghe, "abc").should eq("https://ap-danger:abc@ghe.corp.yahoo.co.jp/hosted-danger/docs")
    remote_from_html_url(html_url_partner, "def").should eq("https://ap-danger:def@partner.git.corp.yahoo.co.jp/hosted-danger/docs")
    remote_from_html_url(html_url_git, "ghi").should eq("https://ap-danger:ghi@git.corp.yahoo.co.jp/hosted-danger/docs")
  end
end
