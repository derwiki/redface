require 'futurama'

def randw
  @dictionary ||= File.read("/usr/share/dict/words").split
  @dictionary_size ||= @dictionary.count
  @dictionary[rand(@dictionary_size)]
end

namespace :playground do
  desc "Playground for rake tasks"
  task :fill => :environment do
    FUTURAMA_NAMES.each do |name|
      first_name = name.split(' ').first
      user = User.create! handle: first_name.downcase,
        email: "#{first_name.downcase}@example.com"
      puts "#{user.handle}: #{user.email}"
    end

    users = User.all
    FUTURAMA_EPISODE_NAMES.each do |name|
      story = Story.create! title: name, url: 'http://localhost:3000',
        user_id: users.shuffle.take(1), votes: rand(100)
      puts "#{story.votes}: #{story.title}, by #{story.user.handle}"
    end
  end

end
