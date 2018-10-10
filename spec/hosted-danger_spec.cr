ENV["SPEC"] = "true"
ENV["ACCESS_TOKEN_GITHUB"] = "dummy"
ENV["ACCESS_TOKEN_TWO"] = "dummy2"
ENV["SD_USER_TOKEN_CD"] = "sd_dummy"
ENV["SD_USER_TOKEN_NEXT"] = "sd_dummy_next"
ENV["DRAGON_ACCESS_KEY"] = "dg_dummy"
ENV["DRAGON_SECRET_ACCESS_KEY"] = "dg_dummy_sec"

HostedDanger::ServerConfig.setup(File.expand_path("../config.yaml", __FILE__))

require "./spec_helper"
require "./units/*"
