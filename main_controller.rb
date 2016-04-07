require_relative 'database'
require_relative 'octokit_client'

class MainController

  @client =

  def initialize
    @db = Database.new
  end

  def add_new_pr (pr_data, repo)
    @db.create_pull_request pr_data, repo
  end

  def checking_pr_for_changes (pr_data, repo)

    existing_pull_requests = get_pr_by_repo repo

    existing_pull_requests.each do |pull_request|
      if pr_data.number.to_i == pull_request.pr_id.to_i

        pr = CLIENT.pull_request(repo, pr_data.number)

        if pull_request.repo != repo
          pull_request.update(repo: repo)
        end

        if pull_request.merged != pr.merged
          pull_request.update(merged: pr.merged)
        end
        if pull_request.state != pr.state
          pull_request.update(state: pr.state)
        end
        if pull_request.mergeable != pr.mergeable
          pull_request.update(mergeable: pr.mergeable)
        end
        if pull_request.mergeable_state != pr.mergeable_state
          pull_request.update(mergeable_state: pr.mergeable_state)
        end
        if pull_request.committer != pr.committer
          pull_request.update(committer: pr.committer)
        end
        if pull_request.labels != pr.label
          pull_request.update(labels: pr.label)
        end
      end
    end
  end

  def create_or_update_pr (pr_data, repo)
    if pr_data.length != 0
      if @db.get_pull_request_by_id pr_data[:number]
        checking_pr_for_changes pr_data, repo
      else
        add_new_pr pr_data, repo
      end
    end
  end

  def add_new_user (login)
    user = get_github_user_by_login login
    create_new_user user
  end

  def sync_user_with_config (user)
    daily_report = user.enable
    user_to_update = @db.get_user_by_login user.login
    user_to_update.update(enable: daily_report, notify_at: user.tz_shift, user_email: user.email)
  end

  def get_all_pr
    @db.get_all_pull_requests
  end

  def get_pr_by_repo (repo)
    @db.get_pull_requests_by_repo repo
  end

  def get_pr_by_id (id)
    @db.get_pull_requests_by_id id
  end

  def get_pr_by_state (state)
    @db.get_pull_requests_by_state state
  end

  def update_pr_state (pr, state)
    @db.update_pull_request_state pr, state
  end

  def get_recipients_list
    @db.get_recipients
  end
end
