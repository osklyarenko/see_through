require 'slack-ruby-client'

class SlackClient
  def initialize
    @logger = Logger.new('logfile.log')
    Slack.configure do |config|
      config.token = ENV['SEE_THROUGH_SLACK_TOKEN']
      fail 'Missing ENV[SEE_THROUGH_SLACK_TOKEN]!' unless config.token
    end

    @slack_client = Slack::Web::Client.new

    @slack_client.auth_test
  end

  def send_message(message, user)
    begin
      @slack_client.chat_postMessage(channel: user, attachments: message, as_user: true)
      @logger.info("Mail was sent to #{user}")
    rescue
      @logger.error("Mail wasn`t sent to #{user}")
    end
  end
end
