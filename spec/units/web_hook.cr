require "../mocks/*"

def spec_context(event : String, headers : HTTP::Headers = HTTP::Headers.new, body : String = "body") : HTTP::Server::Context
  request_headers = HTTP::Headers.new
  request_headers["X-Github-Event"] = event
  request_headers.merge!(headers)
  request = HTTP::Request.new("METHOD", "some_resources", request_headers, body)

  response = HTTP::Server::Response.new(IO::Memory.new)

  HTTP::Server::Context.new(request, response)
end

def query_params_exists
  HTTP::Params.parse("HOGE=true")
end

def query_params_nil
  HTTP::Params.parse("")
end

class MyException < Exception; end

describe HostedDanger::WebHook do
  payloads_root = File.expand_path("../../payloads", __FILE__)

  it "create_payload_json (application/json)" do
    headers = HTTP::Headers.new
    headers["Content-type"] = "application/json"

    context = spec_context("someevent", headers, File.read("#{payloads_root}/pull_request.json"))

    webhook = HostedDanger::WebHook.new
    webhook.create_payload_json(context).should be_truthy
  end

  it "create_payload_json (application/x-www-form-urlencoded)" do
    headers = HTTP::Headers.new
    headers["Content-type"] = "application/x-www-form-urlencoded"

    context = spec_context("someevent", headers, File.read("#{payloads_root}/pull_request_urlencoded.txt"))

    webhook = HostedDanger::WebHook.new
    webhook.create_payload_json(context).should be_truthy
  end

  it "create_executables" do
    webhook = HostedDangerMocks::WebHook.new

    [
      "pull_request",
      "pull_request_review",
      "pull_request_review_comment",
      "issue_comment",
      "issues",
      "status",
    ].each do |event|
      payload_json = JSON.parse(File.read("#{payloads_root}/#{event}.json"))
      webhook.create_executable(spec_context(event), payload_json).should be_truthy
    end
  end

  it "create_executables for unsupported event" do
    webhook = HostedDangerMocks::WebHook.new

    payload_json = JSON.parse(%({"test": "test"}))
    webhook.create_executable(spec_context("unknown"), payload_json).should be_nil
  end

  it "e_pull_request" do
    payload_json = JSON.parse(File.read("#{payloads_root}/pull_request.json"))

    webhook = HostedDanger::WebHook.new

    executables = webhook.e_pull_request("pull_request", payload_json, query_params_exists).not_nil!
    executables.size.should eq(1)

    executable = executables[0]
    executable[:action].should eq("opened")
    executable[:event].should eq("pull_request")
    executable[:html_url].should eq("https://github.com/baxterthehacker/public-repo")
    executable[:pr_number].should eq(1)
    executable[:sha].should eq("0d1a26e67d8f5eaf1f6ba5c57fc3c7d91ac0fd1c")
    executable[:head_label].should eq("baxterthehacker:changes")
    executable[:base_label].should eq("baxterthehacker:master")
    executable[:raw_payload].should eq(payload_json.to_json)
    executable[:env].should eq({"HOGE" => "true"})
  end

  it "e_pull_request_review" do
    payload_json = JSON.parse(File.read("#{payloads_root}/pull_request_review.json"))

    webhook = HostedDanger::WebHook.new

    executables = webhook.e_pull_request_review("pull_request_review", payload_json, query_params_exists).not_nil!
    executables.size.should eq(1)

    executable = executables[0]
    executable[:action].should eq("submitted")
    executable[:event].should eq("pull_request_review")
    executable[:html_url].should eq("https://github.com/baxterthehacker/public-repo")
    executable[:pr_number].should eq(8)
    executable[:raw_payload].should eq(payload_json.to_json)
    executable[:head_label].should eq("skalnik:patch-2")
    executable[:base_label].should eq("baxterthehacker:master")
    executable[:sha].should eq("b7a1f9c27caa4e03c14a88feb56e2d4f7500aa63")
    executable[:env].should eq({"HOGE" => "true"})
  end

  it "e_pull_request_review_comment" do
    payload_json = JSON.parse(File.read("#{payloads_root}/pull_request_review_comment.json"))

    webhook = HostedDanger::WebHook.new

    executables = webhook.e_pull_request_review_comment("pull_request_review_comment", payload_json, query_params_exists).not_nil!
    executables.size.should eq(1)

    executable = executables[0]
    executable[:action].should eq("created")
    executable[:event].should eq("pull_request_review_comment")
    executable[:html_url].should eq("https://github.com/baxterthehacker/public-repo")
    executable[:pr_number].should eq(1)
    executable[:sha].should eq("0d1a26e67d8f5eaf1f6ba5c57fc3c7d91ac0fd1c")
    executable[:head_label].should eq("baxterthehacker:changes")
    executable[:base_label].should eq("baxterthehacker:master")
    executable[:raw_payload].should eq(payload_json.to_json)
    executable[:env].should eq({"HOGE" => "true"})
  end

  it "e_issue_comment" do
    payload_json = JSON.parse(File.read("#{payloads_root}/issue_comment.json"))

    webhook = HostedDangerMocks::WebHook.new

    executables = webhook.e_issue_comment("issue_comment", payload_json, query_params_exists).not_nil!
    executables.size.should eq(1)

    executable = executables[0]
    executable[:action].should eq("created")
    executable[:event].should eq("issue_comment")
    executable[:html_url].should eq("https://github.com/baxterthehacker/public-repo")
    executable[:pr_number].should eq(2)
    executable[:sha].should eq("cdf5ec2d0bfb5457107f07ed8f0dcec2a655c040")
    executable[:head_label].should eq("hosted-danger:taicsuzu-patch-1")
    executable[:base_label].should eq("hosted-danger:master")
    executable[:raw_payload].should eq(payload_json.to_json)
    executable[:env].should eq({
      "HOGE"              => "true",
      "DANGER_PR_COMMENT" => "You are totally right! I'll get this fixed right away.",
    })
  end

  it "e_issues" do
    payload_json = JSON.parse(File.read("#{payloads_root}/issues.json"))

    webhook = HostedDangerMocks::WebHook.new

    executables = webhook.e_issues("issues", payload_json, query_params_exists).not_nil!
    executables.size.should eq(1)

    executable = executables[0]
    executable[:action].should eq("opened")
    executable[:event].should eq("issues")
    executable[:html_url].should eq("https://github.com/baxterthehacker/public-repo")
    executable[:pr_number].should eq(2)
    executable[:sha].should eq("cdf5ec2d0bfb5457107f07ed8f0dcec2a655c040")
    executable[:head_label].should eq("hosted-danger:taicsuzu-patch-1")
    executable[:base_label].should eq("hosted-danger:master")
    executable[:raw_payload].should eq(payload_json.to_json)
    executable[:env].should eq({"HOGE" => "true"})
  end

  it "e_status" do
    payload_json = JSON.parse(File.read("#{payloads_root}/status.json"))

    webhook = HostedDangerMocks::WebHook.new

    executables = webhook.e_status("status", payload_json, query_params_exists).not_nil!
    executables.size.should eq(1)

    executable = executables[0]
    executable[:action].should eq("success")
    executable[:event].should eq("status")
    executable[:html_url].should eq("https://github.com/baxterthehacker/public-repo")
    executable[:pr_number].should eq(1347)
    executable[:sha].should eq("6dcb09b5b57875f334f61aebed695e2e4193db5e")
    executable[:head_label].should eq("new-topic")
    executable[:base_label].should eq("master")
    executable[:raw_payload].should eq(payload_json.to_json)
    executable[:env].should eq({"HOGE" => "true"})
  end

  it "retriable" do
    web_hook = HostedDangerMocks::WebHook.new

    e = 0

    expect_raises(MyException) do
      web_hook.retriable do
        e += 1
        raise MyException.new("getaddrinfo") if e <= 3
      end
    end

    e = 0
    web_hook.retriable do
      e += 1
      raise MyException.new("getaddrinfo") if e <= 2
    end

    e = 0
    web_hook.retriable do
      e += 1
    end

    e.should eq(1)

    e = 0
    expect_raises(MyException) do
      web_hook.retriable do
        e += 1
        raise MyException.new("hogehoge") if e == 1
      end
    end
  end
end
