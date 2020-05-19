  require 'http'
  require 'dotenv'
  require 'eventmachine'
  require 'faye/websocket'
  require 'uri'
  require 'pp'

  Dotenv.load
  GIPHY_API_KEY = ENV['GIPHY_API_KEY']  #https://developers.giphy.com/
  BOT_TOKEN = ENV["BOT_TOKEN"]          #Slack app > Bot
  GIPHY_ENDPOINT = "https://api.giphy.com/v1/gifs/random"
  QUERY_KEYWORD = "hashtag"             #hashtag指定
  SLACK_RTM_URL="https://slack.com/api/rtm.start"
  SLACK_REACTION_URL="https://slack.com/api/reactions.get"
  SLACK_CHANNEL_ID=ENV["SLACK_CHANNEL_ID"]

  def main
    start_app
  end

  def start_app
    EM.run do
      ws_url = get_websocket_url
      ws = Faye::WebSocket::Client.new(ws_url)
      ws.on :open do
        pp [:open]
      end
      ws.on :close do
        pp [:close]
      end
      EM.add_periodic_timer(3600) do
        ws.send({
          type: "message",
          text: get_gif_url,
          channel: SLACK_CHANNEL_ID
        }.to_json)
      end
      ws.on :message do |event|
        data = JSON.parse(event.data)
        if data['text'] == "gif"
          ws.send({
            type: "message",
            text: get_gif_url,
            channel: SLACK_CHANNEL_ID
          }.to_json)
        end
      end
    end
  end

  def get_websocket_url
    response = HTTP.post(SLACK_RTM_URL, params: {
      token: BOT_TOKEN
    })
    raise response unless response.status.success?
    JSON.parse(response.body)["url"]
  end

  # @return url [String] GIF URL
  def get_gif_url
    response = HTTP.get(GIPHY_ENDPOINT, params: {
      api_key: GIPHY_API_KEY,
      tag: QUERY_KEYWORD
    })
    raise response unless response.status.success?
    JSON.parse(response.body)["data"]["url"]
  end

  main
