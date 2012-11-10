class AddPhotoUrlToStory < ActiveRecord::Migration
  def change
    add_column :stories, :photo_url, :text, default: nil
  end
end
