require_relative 'database'
require_relative 'octokit_client'

class MainController

  def initialize
    @db = Database.new
  end

  def add_new_pr pr_data
    @db.create_pull_request pr_data
  end

  def checking_pr_for_changes pr_data

    existing_pull_requests = get_all_pr

    existing_pull_requests.each do |pull_request|
      if pr_data[:number] == pull_request.pr_id
        if pull_request.merged != pr_data[:merged]
          pull_request.update(merged: pr_data[:merged])
        end
        if pull_request.state != pr_data[:state]
          pull_request.update(state: pr_data[:state])
        end
        if pull_request.mergeable != pr_data[:mergeable]
          pull_request.update(mergeable: pr_data[:mergeable])
        end
        if pull_request.mergeable_state != pr_data[:mergeable_state]
          pull_request.update(mergeable_state: pr_data[:mergeable_state])
        end
        if pull_request.committer != pr_data[:committer]
          pull_request.update(committer: pr_data[:committer])
        end
        if pull_request.labels != pr_data[:label]
          pull_request.update(labels: pr_data[:label])
        end
      end
    end
  end

  def create_or_update_pr pr_data
    if pr_data.length != 0
      if @db.get_pull_request_by_id pr_data[:number]
        checking_pr_for_changes pr_data
      else
        add_new_pr pr_data
      end
    end
  end

  def add_new_user login
    user = get_github_user_by_login login
    create_new_user user
  end

  def sync_user_with_config user
    daily_report = user.enable
    user_to_update = @db.get_user_by_login user.login
    user_to_update.update(enable: daily_report, notify_at: user.tz_shift, user_email: user.email)
  end

  def get_all_pr
    @db.get_all_pull_requests
  end

  def get_pr_by_id id
    @db.get_pull_requests_by_id id
  end

  def get_pr_by_state state
    @db.get_pull_requests_by_state state
  end

  def update_pr_state pr, state
    @db.update_pull_request_state pr, state
  end

  def get_recipients_list
    @db.get_recipients
  end
end
