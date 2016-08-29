require_relative 'database'
require_relative 'octokit_client'


class MainController
  def initialize
    @db = Database.new
    @octokit_client = OctokitClient.new
  end

  def checking_pr_for_changes (pr_data, repo)

    pull_request = @db.get_pull_request_by_id pr_data[:number]
    if pr_data.number.to_i == pull_request.pr_id.to_i
      pr = CLIENT.pull_request(repo, pr_data.number)

        if pull_request.repo != repo
          pull_request.update(repo: repo)
        end
        if pull_request.author != pr.user.login
          pull_request.update(author: pr.user.login)
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

  def check_pr_metrics gh_pr_metrics
    pull_request_metrics = @db.get_pr_metrics gh_pr_metrics[:number]
    gh_pr_metrics.each do |k, v|
      if pull_request_metrics[k] != v
        pull_request_metrics.update(k => v)
      end
    end
    
  end

  def create_or_update_pr_metrics repo, number
    db_metrics = @db.get_pr_metrics number
    gh_pr_metrics = @octokit_client.get_pr_metrics(repo, number)
    if !db_metrics
      add_new_pr_metrics gh_pr_metrics
    else
      check_pr_metrics gh_pr_metrics
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

  def add_new_pr (pr_data, repo)
    pr = CLIENT.pull_request(repo, pr_data.number)
    @db.create_pull_request pr_data, repo, pr
  end

  def add_new_pr_metrics(pr_metrics)
    @db.create_new_pr_metrics(pr_metrics)
  end

  def sync_user_with_config (user)
    daily_report = user.enable
    user_to_update = @db.get_user_by_login user.login
    if user_to_update == nil
      @db.create_new_user user
    else
      user_to_update.update(enable: daily_report, notify_at: user.tz_shift, user_email: user.email, slack_id: user.slack_id)
    end
  end

  def update_db_prs_metrics
    get_pr_by_state('open').each do |pr|
      create_or_update_pr_metrics(pr[:repo], pr[:pr_id])
    end
  end

  def get_pr_metrics(number)
    @db.get_pr_metrics(number)
  end

  def get_all_prs_metrics
    @db.get_all_prs_metrics
  end

  def get_repo_pr_by_mergeable (repo, state)
    @db.get_repo_pr_by_mergeable repo, state
  end

  def get_repo_pr_by_state (repo, state)
    @db.get_repo_pr_by_state repo, state
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

  def get_user_by_login login
    @db.get_user_by_login login
  end
end
