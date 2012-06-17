module ApplicationHelper
  def time_formatter(t)
    t.strftime("%k %p on %A")
  end
end
