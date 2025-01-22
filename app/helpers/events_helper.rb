module EventsHelper
  def event_day_title(day)
    case
    when day.today?
      "Today"
    when day.yesterday?
      "Yesterday"
    else
      day.strftime("%A, %B %e")
    end
  end

  def event_column(event)
    case event.action
    when "popped"
      4
    when "published"
      3
    when "commented"
      2
    else
      1
    end
  end

  def event_next_page_link(next_day)
    tag.div id: "next_page", data: { controller: "fetch-on-visible", fetch_on_visible_url_value: events_path(day: next_day) }
  end

  def render_event_grid_cells(day, columns: 4, rows: 24)
    safe_join((2..rows + 1).map do |row|
      (1..columns).map do |col|
        time = day.beginning_of_day + (rows - row + 1).hours
        tag.div class: "event-grid-item", style: "grid-area: #{row}/#{col};", data: { datetime: time.iso8601, timeline_target: "cell" }
      end
    end.flatten)
  end

  def render_time_labels(day)
    safe_join((0..24).step(6).to_a.map do |hour|
      time = day.beginning_of_day + hour.hours
      label = if hour == 24
        "midnight"
      else
        time.strftime("%l:%M %P").strip
      end
      content_tag(:div,
        content_tag(:time,
          label,
          datetime: time.strftime("%H:%M")
        ),
        class: "event-grid-time",
        style: "grid-area: #{25 - (hour * 23/24)}/2 / #{25 - (hour * 23/24)}/4;",
        data: { timeline_target: "cell", datetime: time.iso8601 }
      )
    end)
  end

  def render_column_headers
    [ "Touched", "Discussed", "Added", "Popped" ].map do |header|
      content_tag(:h3, header, class: "event-grid-column-title")
    end.join.html_safe
  end
end
