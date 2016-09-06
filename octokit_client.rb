#!/usr/bin/env rsuby
require 'octokit'
require 'pathname'
require_relative 'main_controller'

CLIENT = Octokit::Client.new(:access_token => ENV['SEE_THROUGH_TOKEN'])

class OctokitClient

  def get_github_pr repo
    pr_data = {}

    begin
      pull_requests = CLIENT.pull_requests(repo)
      pull_requests.each do |pr|
        comments = [].to_set
        pr_label = [].to_set

        pr_additional_data = CLIENT.pull_request(repo, pr.number)
        pr_data[:user_login] = pr.user.login
        pr_data[:title] = pr.title
        pr_data[:number] = pr.number
        pr_data[:merged] = pr_additional_data.merged
        pr_data[:mergeable] = pr_additional_data.mergeable
        pr_data[:mergeable_state] = pr_additional_data.mergeable_state
        pr_data[:pr_create_time] = pr_additional_data.created_at
        pr_data[:pr_update_time] = pr_additional_data.updated_at
        pr_data[:state] = pr_additional_data.state

        iss_comments = CLIENT.issue_comments(repo, pr.number)
        iss_comments.each do |ic|
          label = CLIENT.issue(repo, pr.number)
          label.labels.each do |l|
            pr_label.add(l.name)
          end
          comments.add(ic.user.login)
        end

        pr_data[:pr_label] = pr_label

        pr_comments = CLIENT.pull_request_comments(repo, pr.number)
        pr_comments.each do |k|
          comments.add(k.user.login)
        end

        pr_data[:comments] = comments

        resp = CLIENT.pull_request_commits(repo, pr.number)
        committers = [].to_set
        resp.each do |item|
          if item.committer != nil
            committers.add(item.committer.login)
          else
            committers.add(item.commit.author.name)
          end
        end

        pr_data[:committers] = committers
        pr_data
      end
      pr_data
    rescue
      puts "No pull requests in #{repo}"
    end
    pr_data
  end

  def get_all_github_pr (repo)
    begin
      pulls = CLIENT.pull_requests repo
      if pulls != nil
        return pulls
      end
    rescue
      puts "No pull requests in #{repo}"
    end
  end

  def get_github_user_by_login (login)
    CLIENT.user login
  end

  def get_github_pr_by_number (repo, number)
    CLIENT.pull_request repo, number
  end

  def get_pr_commentors(repo, id)
    commentors = []
    CLIENT.issue_comments(repo, id).each do |comment|
      username = comment[:user][:login]
      post_date = comment[:created_at]
      content = comment[:body]
      
      commentors.push(username)
    end

    CLIENT.pull_request_comments(repo, id).each do |comment|
      username = comment[:user][:login]
      post_date = comment[:created_at]
      content = comment[:body]
      path = comment[:path]
      position = comment[:position]

      commentors.push(username)
    end

    commits = CLIENT.pull_request_commits(repo, id)
    commits.each do |commit|
      CLIENT.commit_comments(repo, commit[:sha]).each do |comment|
        commentors.push(comment[:user][:login])
      end
    end

    commentors.uniq
  end


  def get_pr_committers(repo, id)
    commiters = []
    commits = CLIENT.pull_request_commits(repo, id)
    commits.each do |commit|
      if commit[:author]
        commiters.push(commit[:author][:login])
      elsif commit[:committer]
        commiters.push(commit[:committer][:login])
      end
    end
    commiters.uniq
  end


  def get_pr_metrics(repo, id)
    pr = CLIENT.pull_request(repo, id)
    pr_data = {}
    pr_data[:author] = pr.user.login
    pr_data[:repo] = repo
    pr_data[:title] = pr.title
    pr_data[:number] = pr.number
    pr_data[:merged] = pr.merged
    pr_data[:mergeable] = pr.mergeable
    pr_data[:mergeable_state] = pr.mergeable_state
    pr_data[:create_time] = pr.created_at
    pr_data[:update_time] = pr.updated_at
    pr_data[:state] = pr.state
    pr_data[:additions] = pr.additions
    pr_data[:deletions] = pr.deletions
    pr_data[:changed_files] = pr.changed_files
    pr_data[:commits] = pr.commits
    pr_data[:comments] = pr.comments
    pr_data[:committers] = get_pr_committers(repo, id).join(', ')
    pr_data[:commentors] = get_pr_commentors(repo, id).join(', ')
    pr_data[:head_label] = pr.head.label
    pr_data[:base_sha] = pr.base.sha
    pr_data[:head_sha] = pr.head.sha

    pr_data
  end

  def get_committers_stats_by_pr repo, id, commiters
    commits = CLIENT.pull_request_commits(repo, id)
    commiters_stats = []
    commiters.each do |committer|
      user_commits = []
      commits.each do |commit|
        if commit[:author]
          if commit[:author][:login] == committer
            new_commit = CLIENT.commit(repo, commit[:sha])
            new_user_commit_stats = {}
            new_user_commit_stats[:sha] = new_commit[:sha]
            new_user_commit_stats[:stats] = new_commit[:stats]
            new_user_commit_stats[:changed_files] = new_commit[:files].length
            if new_commit[:commit][:author]
              new_user_commit_stats[:date] = new_commit[:commit][:author][:date]
            elsif new_commit[:commit][:committer]
              new_user_commit_stats[:date] = new_commit[:commit][:committer][:date]
            end
              
            user_commits.push(new_user_commit_stats)
          end
        else
          if commit[:commiter] && commit[:commiter][:login] == committer
            new_commit = CLIENT.commit(repo, commit[:sha])
            new_user_commit_stats = {}
            new_user_commit_stats[:sha] = new_commit[:sha]
            new_user_commit_stats[:stats] = new_commit[:stats]
            new_user_commit_stats[:changed_files] = new_commit[:files].length
            if new_commit[:commit][:author]
              new_user_commit_stats[:date] = new_commit[:commit][:author][:date]
            elsif new_commit[:commit][:committer]
              new_user_commit_stats[:date] = new_commit[:commit][:committer][:date]
            end
              
            user_commits.push(new_user_commit_stats)
          end
        end
      end
      commiters_stats.push({:committer => committer, :commits => user_commits})
    end
    commiters_stats
  end

  def get_master_migrations(repo, path)
    result = CLIENT.contents(repo, :path => path)
    result_names = []
    result.each do |file|
      result_names << file.to_hash[:name]
    end
    result_names.sort_by {|m| m[/\d+__/].to_i}
  end

  def get_pr_migrations(pr_files, path)
    result = []
    pr_files.each do |file|
      f = Pathname.new(file.to_hash[:filename])
      file_name, file_path = f.basename.to_s, f.dirname.to_s
      if file_path == path
        result << file_name
      end
    end
    result.sort_by {|m| m[/\d+__/].to_i}
  end

end
