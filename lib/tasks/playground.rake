require 'futurama'

def randw
  @dictionary ||= File.read("/usr/share/dict/words").split
  @dictionary_size ||= @dictionary.count
  @dictionary[rand(@dictionary_size)]
end

namespace :playground do
  desc "Playground for rake tasks"
  task fill: :environment do
    FUTURAMA_NAMES.each do |name|
      first_name = name.split(' ').first
      user = User.create! handle: first_name.downcase,
        email: "#{first_name.downcase}@example.com"
      puts "#{user.handle}: #{user.email}" if user
    end

    users = User.all
    FUTURAMA_EPISODE_NAMES.each do |name|
      story = Story.new title: name, url: 'http://localhost:3000', votes: rand(100)
      story.user = users.shuffle.take(1).first
      story.created_at = rand(24 * 60).minutes.ago
      story.save!
      puts "#{story.votes}: #{story.title}, by #{story.user.handle}"
    end
  end


  desc "Facebook import from JSON"
  task facebook: :environment do
    newsfeed = JSON.parse(File.read('data/facebook_news_feed.json'))
    unknown_types = Set.new
    newsfeed['data'].each do |story_json|
      # all stories have these attributes
      created_at = Time.zone.parse(story_json['created_time'])
      user_name = story_json['from']['name']
      status_type = story_json['status_type']

      if %w(approved_friend app_created_story added_photos).include? status_type
        next # skip stories we don't want to show
      elsif %w(message mobile_status_update shared_story wall_post).include? status_type
        title = story_json['message']
        votes = story_json['likes'] ? story_json['likes']['count'] : 0
      elsif status_type == 'link'
        title   = story_json['name']
        url     = story_json['link']
        picture = story_json['picture']
      else
        unknown_types << status_type
      end
      title.gsub! /\n/, ' ' if title

      puts [votes, title, user_name, created_at].join(' : ')
      email = "#{user_name.gsub(/ /, '_')}@example.com"
      user = User.create! handle: user_name, email: email
      story = Story.create! title: title, votes: votes, url: url || picture,
                            user_id: user.id, created_at: created_at
    end
    unknown_types.each { |t| puts "Unknown status_type: #{t}" } if unknown_types
  end
end
