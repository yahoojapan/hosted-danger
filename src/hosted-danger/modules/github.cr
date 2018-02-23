module HostedDanger
  module Github
    module State
      ERROR   = "error"
      FAILURE = "failure"
      PENDING = "pending"
      SUCCESS = "success"
    end

    def build_state(
      git_host : String,
      org : String,
      repo : String,
      sha : String,
      description : String,
      access_token : String,
      state : String,
      context : String = "default"
    )
      url = "https://#{git_host}/api/v3/repos/#{org}/#{repo}/statuses/#{sha}"

      puts "---- url ----"
      puts url

      headers = HTTP::Headers.new
      headers["Authorization"] = "token #{access_token}"

      target_url = "https://#{git_host}/#{org}/#{repo}/commit/#{sha}"

      body = {
        state:       state,
        target_url:  target_url,
        description: description,
        context:     context,
      }.to_json

      puts "---- res ----"
      res = HTTP::Client.post(url, headers, body)

      puts res

      JSON.parse(res.body)
    end
  end
end
