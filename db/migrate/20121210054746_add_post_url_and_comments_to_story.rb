class AddPostUrlAndCommentsToStory < ActiveRecord::Migration
  def change
    add_column :stories, :post_id, :bigint
    add_column :stories, :comments, :integer
  end
end
