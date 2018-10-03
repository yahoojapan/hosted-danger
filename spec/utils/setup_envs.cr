def setup_envs_prod(&block)
  ENV["ACCESS_TOKEN_GHE"] = "dummy_ghe"
  ENV["ACCESS_TOKEN_PARTNER"] = "dummy_partner"
  ENV["ACCESS_TOKEN_GIT"] = "dummy_git"
  ENV["DRAGON_ACCESS_KEY"] = "dragon_key"
  ENV["DRAGON_SECRET_ACCESS_KEY"] = "dragon_secret_key"
  ENV["SD_USER_TOKEN_CD"] = "sd_user_token_cd"
  ENV["SD_USER_TOKEN_NEXT"] = "sd_user_token_next"

  yield

  ENV.delete("ACCESS_TOKEN_GHE")
  ENV.delete("ACCESS_TOKEN_PARTNER")
  ENV.delete("ACCESS_TOKEN_GIT")
  ENV.delete("DRAGON_ACCESS_KEY")
  ENV.delete("DRAGON_SECRET_ACCESS_KEY")
  ENV.delete("SD_USER_TOKEN_CD")
  ENV.delete("SD_USER_TOKEN_NEXT")
end
