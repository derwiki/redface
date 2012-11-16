require 'net/https'
require 'uri'

class HomeController < ApplicationController
  def index
  end

  def stories
    fbuid = params[:fbuid].to_i
    stories = Story.for_importer(fbuid)
    render json: stories_json(stories)
  end

  def stories_json(stories)
    {
      count: stories.count,
      html: render_to_string(partial: 'shared/list', layout: false,
                             locals: { stories: stories })
    }
  end

  def import
    access_token = params['accessToken']
    fbuid        = params['userID'].to_i
    story        = Story.where(importer_id: fbuid).last
    if story && (Time.now - story.created_at) < 30.minutes
      Rails.logger.info "Not importing, found story #{story.id} from #{story.created_at}"
      render text: "OK - Cached"
      return
    else
      Rails.logger.info 'Proceeding to hit Facebook'
    end

    url    = "https://graph.facebook.com/me/home?limit=200&access_token=#{access_token}"
    stream = JSON.parse(get_https(url).body)
    total = import_from_stream(stream, fbuid)
    Rails.logger.info "Imported #{total} stories"
    stories = Story.for_importer(fbuid)
    render json: stories_json(stories)
  end

private

  def import_from_stream(resp, fbuid)
    total = 0
    created_ats = Story.where(importer_id: fbuid).pluck(:created_at) # for de-duping
    unknown_types = []
    resp.fetch('data', []).each do |story_json|
      # all stories have these attributes
      created_at  = Time.zone.parse(story_json['created_time'])
      next if created_ats.include?(created_at)
      # return if we already have this timestamp recorded

      user_name   = story_json['from']['name']
      user_fbuid  = story_json['from']['id']
      status_type = story_json['status_type']
      fbid = story_json['id']

      application = story_json['application']
      if status_type == 'app_created_story' && application && application['name'] == 'Spotify'
        next
      elsif %w(approved_friend added_photos).include? status_type
        next # skip stories we don't want to show
      elsif %w(app_created_story message mobile_status_update shared_story wall_post).include? status_type
        title   = story_json['message']
        votes   = story_json['likes'] ? story_json['likes']['count'] : 0
        link    = story_json['link'] || story_json['actions'][0]['link']
        picture = story_json['picture']
      else
        unknown_types << status_type
      end
      unless title
        Rails.logger.info status_type
        next
      end
      title = title.gsub(/\n/, ' ')[0..254]
      url   = (link || picture || "http://www.example.com")[0..254]

      begin
        user = User.create! handle: user_name, email: user_fbuid
        story = Story.create! title: title, votes: votes, url: url,
                              user_id: user.id, created_at: created_at,
                              importer_id: fbuid, photo_url: picture
        total += 1
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error e
      end
    end
    total
  end

  def get_https(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    req = Net::HTTP::Get.new(uri.request_uri)

    http.request(req)
  end
end
