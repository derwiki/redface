module HomeHelper
  def link_to_story(story, opts={})
    title = story.title.length < 255 ? story.title : "#{story.title}.."
    link_to title, story.url, opts
  end

  def link_to_story_poster(story)
    link_to story.user.handle,
            "http://www.facebook.com/profile.php?id=#{story.user.id}"
  end

  def fbuid_small_profile_image_url(fbuid)
    "http://graph.facebook.com/#{fbuid}/picture?type=small"
  end
end
