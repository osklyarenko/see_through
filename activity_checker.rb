require 'rest-client'
require 'digest'
require 'time_difference'
require 'logger'
require_relative 'octokit_client'
require_relative 'main_controller'
require_relative 'config/config_reader'
require_relative 'slack_client'

class ActivityChecker
  def initialize
    @config_reader = Config_reader.new
    @conf = @config_reader.get_activity_checker_configuration
    @repos = @config_reader.get_repos
    @controller = MainController.new
    @client = OctokitClient.new
    @slack_client = SlackClient.new
    @logger = Logger.new('../see_through.log')
    @token = ENV['SEE_THROUGH_TOKEN']

    @config_reader.get_users_from_config_yml.each do |user|
      @controller.sync_user_with_config user
    end
  end

  def check_activity
    @logger.info('activity checker start')

    @repos.each do |repository|
      current_time = Time.now.utc
      repo = repository.repository_name
      prs = @client.get_all_github_pr(repo)
      prs.each do |pr|
        db_pr = @controller.get_pr_by_id(pr[:number]).first
        @controller.create_or_update_pr(pr, repo) if db_pr.nil?

        next if pr_has_label_for_ignoring?(repo, pr[:number])

        new_pr_github_diff_sha = new_pr_diff_sha(repo, pr[:number])
        if new_pr_github_diff_sha
          diff_updated = @controller.get_pr_by_id(pr[:number]).first[:diff_sha].nil? \
                          ? pr[:updated_at] \
                          : current_time
          update_pr_diff_sha(
            pr[:number], 
            new_pr_github_diff_sha, 
            diff_updated
          )
        else
          pr_is_inactive = pr_inactive(pr[:number], current_time)
          if pr_is_inactive and 
            outdated_pr_need_notification?(
              pr[:number], 
              current_time, 
              pr_is_inactive
            )
            update_pr_notified_at(pr[:number], current_time)
            get_pr_notificants(pr[:number]).each do |receiver|
              create_slack_notification_on_outdated_pr(
                repo, 
                pr[:number], 
                pr_is_inactive, 
                receiver
              )
            end
          end
        end
      end
    end
    @logger.info('activity checker end')
  end

  def pr_need_notification?(pr, current_time, days_inactive)
    if !pr[:notified_at]
      return true
    end
    notify = false
    if days_inactive <= 30
      if TimeDifference.between(pr[:notified_at], current_time).in_days.to_i >= 3
        notify = true
      end
    elsif days_inactive > 30
      if TimeDifference.between(pr[:notified_at], current_time).in_days.to_i >= 10
        notify = true
      end
    end
    notify
  end

  def get_pr_diff_sha(repo, number)  
    diff = RestClient.get("https://#{@token}:x-oauth-basic@api.github.com/repos/#{repo}/pulls/#{number}.diff", 
                          {
                            :accept => 'application/vnd.github.diff'
                          })
    Digest::SHA1.hexdigest(diff.body)
  end

  def get_pr_labels(repo, number)
    pr_labels = CLIENT.issue(repo, number)[:labels]
    labels = pr_labels.map {|label| label[:name]}
    labels
  end

  def create_slack_notification_on_outdated_pr(repo, number, days_without_update, recipient)
    pr = @controller.get_pr_by_id(number).first
    attachments = [{
                       fallback: "Outdated Pull Request",
                       title: "##{pr[:pr_id]} - #{pr[:title]}",
                       title_link: "https://github.com/#{repo}/pull/#{pr[:pr_id]}/",
                       text: "This pull request hasn't been updated for #{days_without_update} days.",
                       mrkdwn_in: [
                           "text",
                           "pretext"]
                   }]
    @slack_client.send_message(attachments, recipient)
  end

  def pr_has_label_for_ignoring?(repo, number)
    pr_labels = get_pr_labels(repo, number)
    pr_labels.each do |label|
      if @conf[:labels].include? label
        return true
      end
    end
    false
  end

  def new_pr_diff_sha(repo, number)
    db_pr = @controller.get_pr_by_id(number).first
    pr_github_diff_sha = get_pr_diff_sha(repo, number)

    if not db_pr[:diff_sha] or db_pr[:diff_sha] != pr_github_diff_sha
      return pr_github_diff_sha
    else
      return false
    end
  end

  def pr_inactive(number, current_time)
    db_pr = @controller.get_pr_by_id(number).first
    return nil if db_pr[:diff_updated].nil?

    days_inactive = TimeDifference.between(db_pr[:diff_updated], current_time).in_days.to_i
    if days_inactive >= @conf[:timeout]
      return days_inactive
    else
      return nil
    end
  end

  def outdated_pr_need_notification?(number, current_time, days_inactive)
    db_pr = @controller.get_pr_by_id(number).first
    if !db_pr[:notified_at]
      return true
    end
    last_notified = TimeDifference.between(db_pr[:notified_at], current_time).in_days.to_i

    notify = false
    if days_inactive <= 30
      if last_notified >= 3
        notify = true
      end
    elsif days_inactive > 30
      if last_notified >= 10
        notify = true
      end
    end
    notify
  end

  def get_pr_notificants(number)
    db_pr = @controller.get_pr_by_id(number).first

    pr_notificants = @conf[:recipients]
    user = @controller.get_user_by_login(db_pr[:author])
    if user and user[:enable]
      pr_notificants << user[:slack_id]
    end
    pr_notificants.uniq
  end

  def update_pr_diff_sha(number, new_pr_github_diff_sha, diff_updated)
    @controller.update_pr_diff_sha(
            number,
            new_pr_github_diff_sha,
            diff_updated
          )
  end

  def update_pr_notified_at(number, current_time)
    @controller.update_pr_notified_at(number, current_time)
  end

end

if __FILE__ == $0
  ActivityChecker.new.check_activity
end
