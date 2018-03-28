module HostedDanger
  class SDProxy
    ENDPOINT = "https://api-cd.screwdriver.corp.yahoo.co.jp/v4"

    def auth(context, params)
      puts "Screwdriver auth proxy"
      puts "#{ENDPOINT}/auth/token?api_token=#{Envs.get("sd_user_token")}"

      res = HTTP::Client.get("#{ENDPOINT}/auth/token?api_token=#{Envs.get("sd_user_token")}")

      context.response.status_code = res.status_code
      context.response.print res.body
      context
    end
  end
end
