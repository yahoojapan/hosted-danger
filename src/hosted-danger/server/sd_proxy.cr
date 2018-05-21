module HostedDanger
  class SDProxy
    def auth(context, params)
      auth_internal(context, "https://api-cd.screwdriver.corp.yahoo.co.jp/v4")
    end

    def auth_next(context, params)
      auth_internal(context, "https://api-next.screwdriver.corp.yahoo.co.jp/v4")
    end

    def auth_internal(context, endpoint)
      res = HTTP::Client.get("#{endpoint}/auth/token?api_token=#{Envs.get("sd_user_token")}")

      context.response.status_code = res.status_code
      context.response.print res.body
      context
    end
  end
end
