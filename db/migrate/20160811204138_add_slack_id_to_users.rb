class AddSlackIdToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :slack_id, :string, :null => true
  end
end
