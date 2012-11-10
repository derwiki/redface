class ChangeImporterIdToBigInt < ActiveRecord::Migration
  def change
    change_column :stories, :importer_id, :bigint
  end
end
