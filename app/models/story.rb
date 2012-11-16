class Story < ActiveRecord::Base
  attr_accessible :title, :url, :user_id, :votes, :created_at, :importer_id, :photo_url
  belongs_to :user

  def self.ranking_score(act, exp=1.5)
    denom = ((@now - act.created_at.to_i + 1) / 3600.0) ** exp
    return 0 if denom.zero? || act.votes.nil?
    return act.votes / denom
  end

  def self.ranked_ids_for_pulse(opts={})
    @now = Time.now.to_i
    exp = opts[:exp].to_f || 1.5
    offset = opts[:offset].to_i
    limit = (opts[:limit] || 50).to_i
    acts = Story.select('id, created_at, votes').
                 where('votes > 0').
                 where(created_at: 1.day.ago..Time.now).
                 where(importer_id: opts[:importer_id]).
                 order('id DESC').limit(1000)
    page = acts.sort_by {|act| -ranking_score(act, exp)}.slice(offset, limit)
    Array(page).map(&:id)
  end

  def self.for_importer(fbuid, exp=1.5)
    story_ids = ranked_ids_for_pulse(importer_id: fbuid, exp: exp)
    Rails.logger.info "story_ids: #{story_ids}"
    Story.where(id: story_ids, importer_id: fbuid).includes(:user).
          sort_by { |s| story_ids.index(s.id) }
  end
end
