require_relative 'repository'
require_relative 'profile'

RACK_ENV ||= ENV["RACK_ENV"] || "development"

class Config_reader

  def initialize
    @config = YAML.load_file('../config/conf.yml')
    @db_config = YAML.load_file('db/config.yml')
    @repositories = []
    @profiles = []
  end

  def read_repos
    if RACK_ENV == "test"
      @config['test_repo'].each do |test_repo|
        @repositories.push(Repository.new(
          test_repo['name'],
          test_repo['recepients'],
          test_repo['migration_folders']
        ))
      end
    else
      @config['repositories'].each do |repository|
        @repositories.push(Repository.new(
          repository['name'],
          repository['recepients'],
          repository['migration_folders']
        ))
      end
    end
  end

  def read_users_from_config_yml
    @config['profiles'].each do |profile|
      @profiles.push(Profile.new(profile['login'], profile['email'], profile['id'], profile['slack_id'], profile['tz_shift'], profile['enable']))
    end
  end

  def get_repos
    read_repos
    @repositories
  end

  def get_users_from_config_yml
    read_users_from_config_yml
    @profiles
  end

  def get_activity_checker_configuration
    activity_checker_conf = {}
    activity_checker_conf[:timeout] = @config['activity_checker']['timeout']
    activity_checker_conf[:recipients] = @config['activity_checker']['notify']['slack']
    activity_checker_conf[:labels] = @config['activity_checker']['labels_for_pr_ignoring']
    activity_checker_conf
  end

  def get_db_env_conf
    @db_config[RACK_ENV]
  end

  public :get_repos, :get_users_from_config_yml
  private :read_repos, :read_users_from_config_yml

end
