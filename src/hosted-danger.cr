require "option_parser"

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
    host = "0.0.0.0"
    port = 80
    config = File.expand_path("../../config.yaml", __FILE__)

    OptionParser.parse! do |parser|
      parser.banner = "Usage: hosted-danger [Options]"

      parser.on("-h HOST", "--host=HOST", "Binding host") do |_host|
        host = _host
      end

      parser.on("-p PORT", "--port=PORT", "Binding port") do |_port|
        port = _port.to_i
      end

      parser.on("-c CONFIG", "--config=CONFIG", "Path to the server config yaml") do |_config|
        config = _config
      end

      parser.on("--help", "Show this help") do
        puts parser
        exit 0
      end
    end
    ServerConfig.setup(config)

    server = Server.new
    server.draw_routes
    server.run(host, port)
  end
end

require "./hosted-danger/modules"
require "./hosted-danger/*"
