require 'active_record'
require 'logger'

class Database

  def initialize
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

  class PullRequestMetrics < ActiveRecord::Base
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

  def create_new_pr_metrics(pr_metrics)
    PullRequestMetrics.create(
      :author => pr_metrics[:author],
      :repo => pr_metrics[:repo],
      :number => pr_metrics[:number],
      :title => pr_metrics[:title],
      :merged => pr_metrics[:merged],
      :mergeable => pr_metrics[:mergeable],
      :mergeable_state => pr_metrics[:mergeable_state],
      :create_time => pr_metrics[:create_time],
      :update_time => pr_metrics[:update_time],
      :state => pr_metrics[:state],
      :additions => pr_metrics[:additions],
      :deletions => pr_metrics[:deletions],
      :changed_files => pr_metrics[:changed_files],
      :commits => pr_metrics[:commits],
      :comments => pr_metrics[:comments],
      :committers => pr_metrics[:committers],
      :commentors => pr_metrics[:commentors],
      :head_label => pr_metrics[:head_label],
      :base_sha => pr_metrics[:base_sha],
      :head_sha => pr_metrics[:head_sha],
      :added_to_database => Time.new,
    )
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

# Getters
  def get_pr_metrics(number)
    PullRequestMetrics.find_by(number: number)
  end

  def get_all_prs_metrics
    PullRequestMetrics.all
  end

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
        :adapter => 'sqlite3',
        :database => '../db/data.db'
    )

    ActiveRecord::Schema.new.migrations_paths

  end
end
