module ApplicationHelper
  def full_title(page_title = "")
    base_title = "ShareMyBag"
    page_title.present? ? "#{page_title} — #{base_title}" : "#{base_title} — B2B Airline Baggage Allowance Exchange"
  end

  def format_euros(cents)
    return "—" if cents.nil?
    number_to_currency(cents.to_f / 100.0, unit: "€", separator: ".", delimiter: ",", format: "%u%n")
  end

  def format_kg(weight)
    return "—" if weight.nil?
    val = weight.to_f
    val == val.to_i ? "#{val.to_i} kg" : format("%.1f kg", val)
  end

  def percent_width_class(percent)
    step = ((percent.to_f.clamp(0.0, 100.0)) / 5.0).round * 5
    "smb-w-#{step}"
  end

  def flash_bootstrap_class(key)
    case key.to_sym
    when :success then "success"
    when :notice, :info then "info"
    when :warning then "warning"
    when :error, :alert, :danger then "danger"
    else "secondary"
    end
  end

  def flash_aria_role(key)
    case key.to_sym
    when :error, :alert, :danger, :warning then "alert"
    else "status"
    end
  end

  def status_badge_class(status)
    case status.to_s
    when "open", "filled"           then "smb-badge smb-badge--emerald"
    when "partially_filled"         then "smb-badge smb-badge--sky"
    when "buy"                      then "smb-badge smb-badge--emerald"
    when "sell"                     then "smb-badge smb-badge--amber"
    when "closed", "departed"       then "smb-badge smb-badge--slate"
    when "cancelled"                then "smb-badge smb-badge--muted"
    else "smb-badge smb-badge--slate"
    end
  end

  def user_avatar(user, size: :md)
    palette = %w[brand sky emerald amber slate]
    tone = palette[user.id.to_i % palette.length]
    content_tag(:span, user.initials, class: "smb-avatar smb-avatar--#{size} smb-avatar--#{tone}", "aria-hidden": "true")
  end

  def field_a11y_attrs(object, attribute, required: false, describedby: nil)
    attrs = {}
    attrs[:required] = true if required
    attrs["aria-required"] = "true" if required
    attrs["aria-describedby"] = describedby if describedby.present?
    if object && object.errors[attribute].any?
      attrs["aria-invalid"] = "true"
    end
    attrs
  end

  def notification_target_path(notification)
    case notification.notifiable
    when Flight
      flight_path(notification.notifiable)
    else
      notifications_path
    end
  end
end
