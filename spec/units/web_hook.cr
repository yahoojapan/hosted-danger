require "../mocks/*"

describe HostedDanger::WebHook do
  payloads_root = File.expand_path("../../payloads", __FILE__)

  it "e_pull_request" do
    payload_json = JSON.parse(File.read("#{payloads_root}/pull_request.json"))

    webhook = HostedDanger::WebHook.new

    executables = webhook.e_pull_request(payload_json).not_nil!
    executables.size.should eq(1)

    executable = executables[0]
    executable[:action].should eq("opened")
    executable[:event].should eq("pull_request")
    executable[:html_url].should eq("https://github.com/baxterthehacker/public-repo")
    executable[:pr_number].should eq(1)
    executable[:raw_payload].should eq(payload_json.to_json)
    executable[:sha].should eq("0d1a26e67d8f5eaf1f6ba5c57fc3c7d91ac0fd1c")
    executable[:env].should eq({} of String => String)
  end

  it "e_pull_request_review" do
    payload_json = JSON.parse(File.read("#{payloads_root}/pull_request_review.json"))

    webhook = HostedDanger::WebHook.new

    executables = webhook.e_pull_request_review(payload_json).not_nil!
    executables.size.should eq(1)

    executable = executables[0]
    executable[:action].should eq("submitted")
    executable[:event].should eq("pull_request_review")
    executable[:html_url].should eq("https://github.com/baxterthehacker/public-repo")
    executable[:pr_number].should eq(8)
    executable[:raw_payload].should eq(payload_json.to_json)
    executable[:sha].should eq("b7a1f9c27caa4e03c14a88feb56e2d4f7500aa63")
    executable[:env].should eq({} of String => String)
  end

  it "e_pull_request_review_comment" do
    payload_json = JSON.parse(File.read("#{payloads_root}/pull_request_review_comment.json"))

    webhook = HostedDanger::WebHook.new

    executables = webhook.e_pull_request_review_comment(payload_json).not_nil!
    executables.size.should eq(1)

    executable = executables[0]
    executable[:action].should eq("created")
    executable[:event].should eq("pull_request_review_comment")
    executable[:html_url].should eq("https://github.com/baxterthehacker/public-repo")
    executable[:pr_number].should eq(1)
    executable[:raw_payload].should eq(payload_json.to_json)
    executable[:sha].should eq("0d1a26e67d8f5eaf1f6ba5c57fc3c7d91ac0fd1c")
    executable[:env].should eq({} of String => String)
  end

  it "e_issue_comment" do
    payload_json = JSON.parse(File.read("#{payloads_root}/issue_comment.json"))

    webhook = HostedDangerMocks::WebHook.new

    executables = webhook.e_issue_comment(payload_json).not_nil!
    executables.size.should eq(1)

    executable = executables[0]
    executable[:action].should eq("created")
    executable[:event].should eq("issue_comment")
    executable[:html_url].should eq("https://github.com/baxterthehacker/public-repo")
    executable[:pr_number].should eq(2)
    executable[:raw_payload].should eq(payload_json.to_json)
    executable[:sha].should eq("ok")
    executable[:env].should eq({"DANGER_PR_COMMENT" => "You are totally right! I'll get this fixed right away."} of String => String)
  end

  it "e_status" do
    payload_json = JSON.parse(File.read("#{payloads_root}/status.json"))

    webhook = HostedDangerMocks::WebHook.new

    executables = webhook.e_status(payload_json).not_nil!
    executables.size.should eq(1)

    executable = executables[0]
    executable[:action].should eq("success")
    executable[:event].should eq("status")
    executable[:html_url].should eq("https://github.com/baxterthehacker/public-repo")
    executable[:pr_number].should eq(1)
    executable[:raw_payload].should eq(payload_json.to_json)
    executable[:sha].should eq("ok")
  end
end
