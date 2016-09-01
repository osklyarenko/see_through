class Repository

  attr_accessor :repository_name, :recipients, :migration_folders

  def initialize (name, recipients, migration_folders)
    @repository_name = name
    @recipients = recipients
    @migration_folders = migration_folders
  end
end