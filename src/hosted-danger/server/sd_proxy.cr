module HostedDanger
  class SDProxy
    def auth(context, params)
      auth_internal(
        context,
        "https://api-cd.screwdriver.corp.yahoo.co.jp/v4",
        ServerConfig.secret("sd_user_token_cd"),
      )
    end

    def auth_next(context, params)
      auth_internal(
        context,
        "https://api-next.screwdriver.corp.yahoo.co.jp/v4",
        ServerConfig.secret("sd_user_token_next"),
      )
    end

    def auth_internal(context, endpoint, token)
      res = HTTP::Client.get("#{endpoint}/auth/token?api_token=#{token}")

      context.response.status_code = res.status_code
      context.response.print res.body
      context
    end
  end
end
