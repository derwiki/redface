class Story < ActiveRecord::Base
  attr_accessible :title, :url, :user_id, :votes
  belongs_to :user
end
