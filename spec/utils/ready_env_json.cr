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
