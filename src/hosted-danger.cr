module HostedDanger
  DANGER_ID = "hosted-danger"

  alias Executable = NamedTuple(
    action: String,
    event: String,
    html_url: String,
    pr_number: Int32,
    sha: String,        # build status の変更に使用
    head_label: String, # commitを数えるのに使用
    base_label: String, # commitを数えるのに使用
    raw_payload: String,
    env: Hash(String, String),
  )

  def self.run
    Envs.setup

    server = Server.new
    server.draw_routes
    server.run
  end
end

require "./hosted-danger/modules"
require "./hosted-danger/*"
