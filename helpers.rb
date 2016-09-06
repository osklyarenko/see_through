require_relative 'main_controller'
require_relative 'time_class'
require_relative 'config/config_reader'
require_relative 'octokit_client'

module DB_Utils
	
	@@controller = MainController.new
	@@time = TimeClass.new
	#@@config_reader = Config_reader.new
	

	def get_old_db_prs 
		#repos = @@config_reader.get_repos
		prs = @@controller.get_all_prs_metrics.sort_by &:update_time
		prs.reverse!
		last = prs.first
		p prs.length
		if prs.length == 0 || TimeDifference.between(last.update_time, Time.new).in_days.to_i >= 1
			@@controller.update_db_prs_metrics
			prs = (@@controller.get_all_prs_metrics.sort_by &:update_time).reverse
		end
	
		result = []

		prs.each do |pr|
			time_without_updating = TimeDifference.between(pr.update_time, Time.new).in_days.to_i
			
			if time_without_updating >= 5
				result.push(pr)
			end
		end
		result
	end

	def get_pr(id)
		@@controller.get_pr_metrics (id)
	end

end

module Login

	CLIENT_ID = ENV['SEE_THROUGH_GH_CLIENT_ID']
  CLIENT_SECRET = ENV['SEE_THROUGH_GH_CLIENT_SECRET']

	def authenticated?
	  session[:access_token]
	end

	def authenticate!(message=nil)
	  erb :login, :locals => {:client_id => CLIENT_ID, :message => message}, :layout => :base
	end

	def get_auth_orgs
		Config_reader.new.get_auth_orgs
	end
end

module OctokitUtils
	@@octokit_client = OctokitClient.new

	
	def get_committers_stats_by_pr repo, number, committers
		@@octokit_client.get_committers_stats_by_pr repo, number, committers
	end

	def get_committers_stats_by_repo
		repos = @@config_reader.get_repos
		repo_committer_stats = []
		repos.each do |repo|

		end
	end
end