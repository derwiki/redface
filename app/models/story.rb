class Story < ActiveRecord::Base
  attr_accessible :title, :url, :user_id, :votes, :created_at, :importer_id, :photo_url
  belongs_to :user
end
