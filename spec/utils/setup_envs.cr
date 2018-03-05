def setup_envs_prod(&block)
  ENV["ACCESS_TOKEN_GHE"] = "dummy_ghe"
  ENV["ACCESS_TOKEN_PARTNER"] = "dummy_partner"
  ENV["ACCESS_TOKEN_GIT"] = "dummy_git"
  ENV["DRAGON_ACCESS_KEY"] = "dragon_key"
  ENV["DRAGON_SECRET_ACCESS_KEY"] = "dragon_secret_key"

  HostedDanger::Envs.setup

  yield

  HostedDanger::Envs.clear
end

def setup_envs_dev(&block)
  ready_env_json
  HostedDanger::Envs.setup

  yield

  HostedDanger::Envs.clear
  clean_env_json
end

def ready_env_json
  setenv_binary = File.expand_path("../../../tools/setenv", __FILE__)

  envs = [
    ["ACCESS_TOKEN_GHE", "dummy_ghe"],
    ["ACCESS_TOKEN_PARTNER", "dummy_partner"],
    ["ACCESS_TOKEN_GIT", "dummy_git"],
    ["DRAGON_ACCESS_KEY", "dragon_key"],
    ["DRAGON_SECRET_ACCESS_KEY", "dragon_secret_key"],
  ].map { |env| env.join("=") }.join(" ")

  `#{envs} #{setenv_binary}`
end

def clean_env_json
  env_json = File.expand_path("../../../envs.json", __FILE__)

  File.delete(env_json) if File.exists?(env_json)
end
