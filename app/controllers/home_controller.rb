class HomeController < ApplicationController
  def index
    story_ids = ranked_ids_for_pulse
    @stories = Story.where(id: story_ids).sort_by { |s| story_ids.index(s.id) }
  end

private

  def ranking_score(act, exp=1.5)
    denom = ((@now - act.created_at.to_i + 1) / 3600.0) ** exp
    return 0 if denom == 0
    return act.votes / denom
  end

  def ranked_ids_for_pulse(opts={})
    @now = Time.now.to_i
    exp = opts[:exp].to_f || 1.5
    offset = opts[:offset].to_i
    limit = (opts[:limit] || 20).to_i
    acts = Story.select('id, created_at, votes').order('id DESC').limit(1000)
    page = acts.sort_by {|act| -ranking_score(act, exp)}.slice(offset, limit)
    Array(page).map(&:id)
  end
end
