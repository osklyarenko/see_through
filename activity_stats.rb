require 'sinatra/base'
require 'rest-client'
require 'json'
require 'chartkick'
require_relative 'helpers'


class MyApp < Sinatra::Base
 	include DB_Utils, Login, OctokitUtils

 	use Rack::Session::Pool, :cookie_only => false
 	set :public_folder, File.dirname(__FILE__) + '/public'
 	set :bind, '0.0.0.0'

  get('/') do
  	if !authenticated?
      authenticate!
    else
	  	res = "<ul>" 
	  	old_pull_requests = get_old_db_prs
	  	pr_timeline = []
	  	old_pull_requests.each do |pr|
	  		pr_timeline.push([pr.number.to_s, pr.update_time, Time.new])
	  		res << "<li><a href='/pull/#{pr.number}'>#{pr.number}</a></li>"
	  	end
	  	res << "</ul>"
	  
	  	erb :index, :locals => {:prs_list => res, :old_prs => pr_timeline}, :layout => :base
	  end
  end

  get('/pull/:id') do |id|
  	if !authenticated?
      authenticate!
    else
    	result = "<ul>"
	  	pr = get_pr(id)
	  	pr = pr.serializable_hash
	  	pr.each do |k, v|
	  		result << "<li>#{k}: #{v}</li>"
	  	end
	  	result << "</ul>"
	  	committers = pr['committers'].split(', ')
	  
	  	committers_stats = get_committers_stats_by_pr(pr['repo'], pr['number'], committers)
	  	committers_stats_graph = []
	  	committers_total = []

	  	committers_stats.each do |cs|
	  		t_additions, t_deletions, t_files = 0, 0, 0
	  		committer_total = {}
	  		t_commits = cs[:commits].length
	  		cs[:commits].each do |commit|
	  			t_additions += commit[:stats][:additions]
	  			t_deletions += commit[:stats][:deletions]
	  			t_files += commit[:changed_files]
	  			if committer_total[commit[:date].to_date.strftime("%Y-%m-%d")]
	  				committer_total[commit[:date].to_date.strftime("%Y-%m-%d")] += commit[:stats][:additions] + commit[:stats][:deletions]
	  			else
	  				committer_total[commit[:date].to_date.strftime("%Y-%m-%d")] = commit[:stats][:additions] + commit[:stats][:deletions]
	  			end
	  		end

	  		committers_total.push({name: cs[:committer], data: committer_total })
	  		committers_stats_graph.push([cs[:committer], t_commits])
	  	end

	  	erb :pull, :locals => {:pr_metrics => result, :pr_committers_stats => committers_stats_graph, 
	  												 :committers_total => committers_total}, :layout => :base

	  end
  end

  get '/callback' do
	  session_code = request.env['rack.request.query_hash']['code']

	  result = RestClient.post('https://github.com/login/oauth/access_token',
	                          {:client_id => CLIENT_ID,
	                           :client_secret => CLIENT_SECRET,
	                           :code => session_code},
	                           :accept => :json)

	  access_token = JSON.parse(result)['access_token']
 		user_orgs = JSON.parse(RestClient.get('https://api.github.com/user/orgs', 
 																		{:params => {:access_token => access_token},
                                    :accept => :json}))

	  auth_orgs = get_auth_orgs
	  user_orgs.each do |org|
	  	if auth_orgs.include? org['login']
	  		session[:access_token] = access_token
	  		redirect '/'
	  	end
	  end

	  authenticate!("You organization is not allowed.")
	end

end

MyApp.run!