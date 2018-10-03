def setup_envs(&block)
  ENV["ACCESS_TOKEN_GITHUB"] = "dummy_token"
  ENV["ACCESS_TOKEN_TWO"] = "dummy_token_two"
  ENV["DRAGON_ACCESS_KEY"] = "dragon_key"
  ENV["DRAGON_SECRET_ACCESS_KEY"] = "dragon_secret_key"
  ENV["SD_USER_TOKEN_CD"] = "sd_user_token_cd"
  ENV["SD_USER_TOKEN_NEXT"] = "sd_user_token_next"

  yield

  ENV.delete("ACCESS_TOKEN_GITHUB")
  ENV.delete("ACCESS_TOKEN_TWO")
  ENV.delete("DRAGON_ACCESS_KEY")
  ENV.delete("DRAGON_SECRET_ACCESS_KEY")
  ENV.delete("SD_USER_TOKEN_CD")
  ENV.delete("SD_USER_TOKEN_NEXT")
end
