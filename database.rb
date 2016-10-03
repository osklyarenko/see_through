require 'active_record'
require 'logger'
require_relative 'config/config_reader'

class Database

  def initialize
    @conf = Config_reader.new.get_db_env_conf
    init_database
    @logger = Logger.new('../see_through.log')
  end

  class User < ActiveRecord::Base
    belongs_to :commentors
  end

  class PullRequest < ActiveRecord::Base
    has_many :commentors
  end

  class Commentor < ActiveRecord::Base
    belongs_to :pull_request
    has_one :users
  end

  class Repository < ActiveRecord::Base
  end

  class DailyReport < ActiveRecord::Base
  end

  def create_pull_request (pull_request_data, repo, pr)
    PullRequest.create(
        :repo => repo,
        :title => pull_request_data[:title],
        :pr_id => pull_request_data[:number],
        :author => pull_request_data[:user][:login],
        :merged => pr.merged,
        :mergeable => pr.mergeable,
        :mergeable_state => pr.mergeable_state,
        :state => pull_request_data[:state],
        # :pr_commentors => pull_request_data[:commentors].to_a.join(', '),
        :committer => pull_request_data[:committer].to_a.join(', '),
        :labels => pr.head.label,
        :pr_create_time => pull_request_data[:created_at],
        :pr_update_time => pull_request_data[:updated_at],
        :added_to_database => Time.new,
    )
    # commentors = pull_request_data[:commentors].to_a
    # build_list_of_commentors commentors
    @logger.info("Pull request##{pull_request_data[:number]} was added to database!")
  end

  def create_new_user (user)
    User.create(
        :user_login => user.login,
        :user_email => user.email,
        :notify_at => user.tz_shift,
        :git_hub_id => user.id,
        :slack_id => user.slack_id,
        :enable => false,
    )
  end

  def create_daily_report (user_login, sent_time)
    DailyReport.create(
        :user_name => user_login,
        :sent_at => sent_time,
    )
  end

  def create_repository (repository)
    Repository.create(
        :repo => repository
    )
  end

  def update_daily_report_date (user_login, sent_time)
    dr = DailyReport.where(user_name: user_login).first
    dr.update(:sent_at => sent_time)
  end

  def update_pull_request_state (pull_request, state)
    pull_request.update(state: state)
  end

  def update_pr_migration_conflict(pr_id, has_migration_conflict)
    pr = get_pull_request_by_id(pr_id.to_i)
    pr.update(has_migration_conflict: has_migration_conflict)
  end

  def update_pr_diff_sha(number, diff_sha, diff_updated)
    PullRequest.where(pr_id: number).first.update({
      :diff_sha => diff_sha, 
      :diff_updated => diff_updated
    })
  end

  def update_pr_notified_at(id, notified_at)
    PullRequest.where(pr_id: id).first.update(notified_at: notified_at)
  end

# Getters
  def get_daily_report_state (user_login)
    DailyReport.where(user_name: user_login).first
  end

  def get_daily_reports_state
    DailyReport.all
  end

  def get_repo_pr_by_state (repo, state)
    PullRequest.where(repo: repo, state: state)
  end

  def get_pull_requests_by_repo (repo)
    PullRequest.where(repo: repo)
  end

  def get_all_repositories
    Repository.all
  end
      
  def get_repo_prs_with_migration_conflict(repo)
    PullRequest.where(repo: repo, state: 'open', has_migration_conflict: true)
  end

  def get_repo_pr_by_mergeable (repo, state)
    PullRequest.where(repo: repo, mergeable: state)
  end

  def get_pull_requests_by_mergeable (state)
    PullRequest.where(mergeable: state)
  end

  def get_pull_requests_by_id (id)
    PullRequest.where(pr_id: id)
  end

  def get_all_pull_requests
    PullRequest.all
  end

  def get_pull_requests_by_state (state)
    PullRequest.all.where(state: state)
  end

  def get_pull_request_by_id (pull_request_id)
    PullRequest.find_by(pr_id: pull_request_id)
  end

  def get_recipients
    User.all.where(enable: true)
  end

  def get_user_by_login (login)
    User.where(user_login: login).take
  end

  def init_database

    ActiveRecord::Base.logger = Logger.new(File.open('../database.log', 'w'))

    ActiveRecord::Base.establish_connection(
        :adapter => @conf["adapter"],
        :database => @conf["database"]
    )

    ActiveRecord::Schema.new.migrations_paths

  end
end
