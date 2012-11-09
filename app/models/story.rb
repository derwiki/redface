class Story < ActiveRecord::Base
  attr_accessible :title, :url, :user_id, :votes, :created_at
  belongs_to :user
end
