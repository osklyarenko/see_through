class AddHasMigrationConflictToPullRequests < ActiveRecord::Migration
  def change
    add_column :pull_requests, :has_migration_conflict, :boolean, :null => true
  end
end
