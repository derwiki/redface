class CreateStories < ActiveRecord::Migration
  def change
    create_table :stories do |t|
      t.string :title
      t.string :url
      t.integer :user_id
      t.integer :votes

      t.timestamps
    end
  end
end
