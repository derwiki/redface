class HomeController < ApplicationController
  def index
    story_ids = ranked_ids_for_pulse
    @stories = Story.where(id: story_ids).sort_by { |s| story_ids.index(s.id) }
  end

  def import
    access_token = params['authResponse']['accessToken']
    url = "https://graph.facebook.com/me/home?limit=500&access_token=#{access_token}"
    Rails.logger.info "eyecatcher: #{url}"
    stream = JSON.parse(`curl #{url}`)
    Rails.logger.info "eyecatcher: #{stream}"
    import_from_stream(stream)
    render text: 'OK'
  end

private

  def import_from_stream(newsfeed)
    unknown_types = []
    newsfeed.fetch('data', []).each do |story_json|
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
  end

  def ranking_score(act, exp=1.5)
    denom = ((@now - act.created_at.to_i + 1) / 3600.0) ** exp
    return 0 if denom.zero? || act.votes.nil?
    return act.votes / denom
  end

  def ranked_ids_for_pulse(opts={})
    @now = Time.now.to_i
    exp = opts[:exp].to_f || 1.5
    offset = opts[:offset].to_i
    limit = (opts[:limit] || 20).to_i
    acts = Story.select('id, created_at, votes').
                 where('votes > 0').
                 order('id DESC').limit(1000)
    page = acts.sort_by {|act| -ranking_score(act, exp)}.slice(offset, limit)
    Array(page).map(&:id)
  end
end
