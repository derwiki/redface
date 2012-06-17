class User < ActiveRecord::Base
  attr_accessible :email, :handle
  has_many :story
end
