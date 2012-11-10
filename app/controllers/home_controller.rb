require 'net/https'
require 'uri'

class HomeController < ApplicationController
  def index
  end

  def stories
    fbuid = params[:fbuid].to_i
    Rails.logger.info "fbuid: #{fbuid}"
    story_ids = ranked_ids_for_pulse(importer_id: fbuid)
    Rails.logger.info "story_ids: #{story_ids}"
    stories = Story.where(id: story_ids, importer_id: fbuid).
                    includes(:user).
                    sort_by { |s| story_ids.index(s.id) }
    json = {
      count: stories.count,
      html: render_to_string(partial: 'shared/list', layout: false,
                             locals: { stories: stories })
    }
    Rails.logger.info "Response: #{json}"
    puts json
    render json: json
  end

  def import
    access_token = params['authResponse']['accessToken']
    fbuid        = params['authResponse']['userID']
    url          = "https://graph.facebook.com/me/home?limit=100&access_token=#{access_token}"
    stream       = JSON.parse(get_https(url).body)
    total        = 0
    ActiveRecord::Base.transaction do
      total = import_from_stream(stream, fbuid)
    end
    Rails.logger.info "Imported #{total} stories"
    render text: "OK - #{total}"
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
      next unless title
      title.gsub! /\n/, ' '
      title = title[0..254]
      url = url || picture || "http://www.example.com"
      url = url[0..254]

      Rails.logger.info [votes, title, user_name, created_at].join(' : ')
      email = "#{user_name.gsub(/ /, '_')}@example.com"
      user = User.create! handle: user_name, email: email
      story = Story.create! title: title, votes: votes, url: url,
                            user_id: user.id, created_at: created_at,
                            importer_id: fbuid
      total += 1
    end
    total
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
                 where(importer_id: opts[:importer_id]).
                 order('id DESC').limit(1000)
    page = acts.sort_by {|act| -ranking_score(act, exp)}.slice(offset, limit)
    Array(page).map(&:id)
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
