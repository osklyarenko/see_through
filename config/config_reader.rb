require_relative 'repository'
require_relative 'profile'

class Config_reader

  def initialize
    @config = YAML.load_file('conf.yml')
    @repositories = []
    @profiles = []
    @auth_orgs = []
  end

  def read_repos
    @config['repositories'].each do |repository|
      @repositories.push(Repository.new(repository['name'], repository['recepients']))
    end
  end

  def read_users_from_config_yml
    @config['profiles'].each do |profile|
      @profiles.push(Profile.new(profile['login'], profile['email'], profile['id'], profile['slack_id'], profile['tz_shift'], profile['enable']))
    end
  end

  def read_auth_orgs
    @config['auth_orgs'].each do |org|
      @auth_orgs.push(org)
    end
  end

  def get_auth_orgs
    read_auth_orgs
    @auth_orgs
  end

  def get_repos
    read_repos
    @repositories
  end

  def get_users_from_config_yml
    read_users_from_config_yml
    @profiles
  end

  public :get_repos, :get_users_from_config_yml, :get_auth_orgs
  private :read_repos, :read_users_from_config_yml, :read_auth_orgs

end
