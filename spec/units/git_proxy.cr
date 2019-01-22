def spec_context : HTTP::Server::Context
  request_headers = HTTP::Headers.new
  request_headers["hoge"] = "fuga"
  request_headers["Authorization"] = "invalid"
  request_headers["Host"] = "localhost"

  request = HTTP::Request.new("METHOD", "/proxy/git/resource", request_headers, "body")

  response = HTTP::Server::Response.new(IO::Memory.new)

  HTTP::Server::Context.new(request, response)
end

def spec_git_context
  {
    symbol:       "git",
    git_host:     "github.com",
    access_token: "dummy",
  }
end

describe HostedDanger::GitProxy do
  api_path = File.expand_path("../../api", __FILE__)

  it "rewrite_headers" do
    git_proxy = HostedDanger::GitProxy.new

    headers = git_proxy.rewrite_headers(spec_context, spec_git_context)
    headers["hoge"].should eq("fuga")
    headers["Authorization"].should eq("token dummy")
  end

  it "rewrite_resource" do
    git_proxy = HostedDanger::GitProxy.new

    resource = git_proxy.rewrite_resource(spec_context, spec_git_context)
    resource.should eq("resource")
  end

  it "convert_body for api(pulls)" do
    git_proxy = HostedDanger::GitProxy.new

    body = git_proxy.convert_body(File.read("#{api_path}/pull.json"), spec_git_context).not_nil!
    body_json = JSON.parse(body)
    body_json["_links"]["issue"]["href"].as_s.should eq("http://localhost/proxy/git/repos/hosted-danger/hosted-danger/issues/3")
  end

  it "convert_body for api(issues) without any errors" do
    git_proxy = HostedDanger::GitProxy.new
    git_proxy.convert_body(File.read("#{api_path}/issues.json"), spec_git_context).should be_truthy
  end

  it "convert_body for api(comments) without any errors" do
    git_proxy = HostedDanger::GitProxy.new
    git_proxy.convert_body(File.read("#{api_path}/comments.json"), spec_git_context).should be_truthy
  end
end
