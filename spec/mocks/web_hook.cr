require "./parser"
require "./github"

module HostedDangerMocks
  class WebHook < ::HostedDanger::WebHook
    include HostedDangerMocks::Github
    include HostedDangerMocks::Parser
  end
end
