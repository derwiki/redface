class AddImporterIdToStory < ActiveRecord::Migration
  def change
    add_column :stories, :importer_id, :integer, default: nil
  end
end
