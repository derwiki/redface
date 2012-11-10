module HomeHelper
  def link_to_story_poster(story)
    link_to story.user.handle,
            "http://www.facebook.com/profile.php?id=#{story.user.id}"
  end
end
