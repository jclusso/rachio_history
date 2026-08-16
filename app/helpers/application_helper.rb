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

  # Zone numbers sit immediately left of long zone names. A fixed-width,
  # right-aligned slot keeps them lining up in a column and stops them reading
  # as the first word of the name.
  def zone_number_badge(number)
    tag.span number, class: "mr-3 inline-block w-5 text-right tabular-nums text-gray-400"
  end

  # Label/value rows for the device cards. The label is set in the same small
  # uppercase grey as the section headings so it reads as a label rather than
  # as the first word of the value.
  def detail_row(label, value)
    tag.div class: "flex gap-3" do
      tag.dt(label, class: "w-24 shrink-0 pt-px text-xs font-semibold uppercase tracking-wider text-gray-400") +
        tag.dd(value.presence || "—", class: "font-medium text-gray-800")
    end
  end

  # One-line hardware summary, shown on hover rather than taking up a line of
  # its own under the controller name.
  def device_summary(controller)
    [
      controller.model,
      ("activated #{controller.rachio_created_at.to_date.strftime('%b %-d, %Y')}" if controller.rachio_created_at),
      ("includes history merged from #{controller.predecessors.map(&:name).to_sentence}" if controller.predecessors.any?)
    ].compact_blank.join(" · ")
  end

  # The window a controller has history for, e.g. "Jul 20, 2025 – Jul 18, 2026".
  def event_span(controller)
    first, last = controller.events.pick(Arel.sql("MIN(occurred_at), MAX(occurred_at)"))
    return "no events" if first.blank?

    [ first, last ].map { |time| time.to_date.strftime("%b %-d, %Y") }.uniq.join(" – ")
  end

  def duration_in_words(seconds)
    return "-" if seconds.to_i.zero?
    minutes = seconds.to_i / 60
    minutes >= 1 ? "#{minutes} min" : "#{seconds} sec"
  end
end
