class CreatePullRequestMetrics < ActiveRecord::Migration
  def change
  	ActiveRecord::Schema.define do
	    create_table :pull_request_metrics do |t|
	    	t.column :author, :string
	      t.column :number, :string, :null => false
	      t.column :repo, :string
	      t.column :title, :string
	      t.column :merged, :boolean
	      t.column :mergeable, :boolean
	      t.column :mergeable_state, :string
	      t.column :create_time, :string
	      t.column :update_time, :string
	      t.column :state, :string
	      t.column :additions, :string
	      t.column :deletions, :string
	      t.column :changed_files, :string
	      t.column :commits, :string
	      t.column :comments, :string
	      t.column :committers, :string, :null => true
	      t.column :commentors, :string, :null => true
	      t.column :head_label, :string
	      t.column :base_sha, :string
	      t.column :head_sha, :string
	      t.column :added_to_database, :string, :null => false

	      #t.timestamps :null => false
	    end
	  end
  end
end
