class Story < ActiveRecord::Base
  attr_accessible :title, :url, :user_id, :votes, :created_at, :importer_id
  belongs_to :user
end
