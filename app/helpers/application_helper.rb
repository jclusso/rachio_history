module ApplicationHelper
  STATUS_BADGE_COLORS = {
    "ONLINE" => "bg-emerald-100 text-emerald-800",
    "OFFLINE" => "bg-red-100 text-red-800"
  }.freeze

  def status_badge(status)
    return if status.blank?

    colors = STATUS_BADGE_COLORS.fetch(status.to_s.upcase, "bg-gray-100 text-gray-700")
    tag.span status.to_s.downcase.capitalize, class: "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium #{colors}"
  end

  def boolean_badge(value, yes: "Enabled", no: "Disabled")
    colors = value ? "bg-emerald-100 text-emerald-800" : "bg-gray-100 text-gray-500"
    tag.span (value ? yes : no), class: "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium #{colors}"
  end

  def event_type_badge(event)
    label = [ event.event_type, event.sub_type ].compact_blank.join(" - ").tr("_", " ").downcase
    colors = event.zone_run? ? "bg-sky-100 text-sky-800" : "bg-gray-100 text-gray-600"
    tag.span label, class: "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium whitespace-nowrap #{colors}"
  end

  # Intensity scale for the watering heatmap.
  def heat_class(minutes)
    case minutes.to_i
    when 0 then "bg-gray-100"
    when 1..10 then "bg-emerald-200"
    when 11..25 then "bg-emerald-300"
    when 26..60 then "bg-emerald-400"
    when 61..120 then "bg-emerald-500"
    else "bg-emerald-600"
    end
  end

  def duration_in_words(seconds)
    return "-" if seconds.to_i.zero?
    minutes = seconds.to_i / 60
    minutes >= 1 ? "#{minutes} min" : "#{seconds} sec"
  end
end
