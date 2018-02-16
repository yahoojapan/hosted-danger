require "json"

module HostedDanger
  alias Executable = NamedTuple(html_url: String, pr_number: Int32)

  class WebHook
    def initialize
    end

    def hook(context, params)
      payload : String = if body = context.request.body
        body.gets_to_end
      else
        raise "Empty body"
      end

      payload_json = JSON.parse(payload)

      executable? = create_executable(context, payload_json)

      if executable = executable?
        exec_danger(executable)
      end

      context.response.status_code = 200
      context.response.print "OK"
      context
    rescue e : Exception
      L.error e.message.not_nil!

      context.response.status_code = 400
      context.response.print "Bad Request"
      context
    end

    def create_executable(context, payload_json) : Executable?
      event = context.request.headers["X-GitHub-Event"]

      return e_pull_request(payload_json) if event == "pull_request"
      return e_issue_comment(payload_json) if event == "issue_comment"

      L.info "danger will not be triggered (#{event})"
    end

    def e_pull_request(payload_json) : Executable?
      return L.info "skip: sender is ap-approduce" if payload_json["sender"]["login"] == "ap-approduce"
      return L.info "skip: closed" if payload_json["action"] == "closed"

      {
        html_url:  payload_json["pull_request"]["head"]["repo"]["html_url"].as_s,
        pr_number: payload_json["number"].as_i,
      }
    end

    def e_issue_comment(payload_json) : Executable?
      return L.info "skip: sender is ap-approduce" if payload_json["sender"]["login"] == "ap-approduce"
      return L.info "skip: deleted" if payload_json["action"] == "deleted"

      if payload_json["issue"]["html_url"].as_s =~ /(.*)\/pull\/(.*)/
        return {
          html_url:  $1.to_s,
          pr_number: $2.to_i,
        }
      end

      nil
    end

    include Executor
  end
end
