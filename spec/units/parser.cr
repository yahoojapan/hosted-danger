include HostedDanger::Parser

describe HostedDanger::Parser do
  html_url_ghe = "https://ghe.corp.yahoo.co.jp/hosted-danger/docs"
  html_url_partner = "https://partner.git.corp.yahoo.co.jp/hosted-danger/docs"

  ghe = "ghe.corp.yahoo.co.jp"
  partner = "partner.git.corp.yahoo.co.jp"

  it "git_host_from_html_url" do
    git_host_from_html_url(html_url_ghe).should eq(ghe)
    git_host_from_html_url(html_url_partner).should eq(partner)
  end

  it "access_token_from_git_host" do
    ENV["DANGER_GITHUB_API_TOKEN_GHE"] = "abc"
    ENV["DANGER_GITHUB_API_TOKEN_PARTNER"] = "def"

    access_token_from_git_host(ghe).should eq("abc")
    access_token_from_git_host(partner).should eq("def")
  end

  it "org_repo_from_html_url" do
    org_repo_from_html_url(html_url_ghe).should eq(["hosted-danger", "docs"])
    org_repo_from_html_url(html_url_partner).should eq(["hosted-danger", "docs"])
  end

  it "remote_from_html_url" do
    remote_from_html_url(html_url_ghe, "abc").should eq("https://ap-danger:abc@ghe.corp.yahoo.co.jp/hosted-danger/docs")
    remote_from_html_url(html_url_partner, "def").should eq("https://ap-danger:def@partner.git.corp.yahoo.co.jp/hosted-danger/docs")
  end
end
