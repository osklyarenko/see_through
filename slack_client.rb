require 'slack-ruby-client'

class SlackClient
  def initialize
    @logger = Logger.new('../see_through.log')
    Slack.configure do |config|
      config.token = ENV['SEE_THROUGH_SLACK_TOKEN']
      fail 'Missing ENV[SEE_THROUGH_SLACK_TOKEN]!' unless config.token
    end

    @slack_client = Slack::Web::Client.new
  end

  def send_message(message, user)
    begin
      @slack_client.chat_postMessage(channel: user, attachments: message, as_user: true)
      @logger.info("Notification was sent to #{user}")
    rescue
      @logger.error("Notification wasn`t sent to #{user}")
    end
  end
end
