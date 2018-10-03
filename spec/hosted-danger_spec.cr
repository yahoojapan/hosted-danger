ENV["SPEC"] = "true"
HostedDanger::ServerConfig.setup(File.expand_path("../config.yaml", __FILE__))

require "./spec_helper"
require "./utils/*"
require "./units/*"
