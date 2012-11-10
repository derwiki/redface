class ChangeIdsToBigInt < ActiveRecord::Migration
  def change
    change_column :stories, :user_id, :bigint
  end
end
