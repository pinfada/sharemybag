module ApplicationHelper
  def full_title(page_title = "")
    base_title = "ShareMyBag"
    page_title.present? ? "#{page_title} — #{base_title}" : "#{base_title} — Peer-to-peer parcel delivery by reverse auction"
  end

  def format_euros(cents)
    return "—" if cents.nil?
    number_to_currency(cents.to_f / 100.0, unit: "€", separator: ".", delimiter: ",", format: "%u%n")
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
    when "open"        then "smb-badge smb-badge--emerald"
    when "bidding"     then "smb-badge smb-badge--sky"
    when "accepted", "handed_over", "in_progress", "in_transit" then "smb-badge smb-badge--brand"
    when "delivered"   then "smb-badge smb-badge--amber"
    when "completed", "confirmed" then "smb-badge smb-badge--emerald"
    when "pending"     then "smb-badge smb-badge--slate"
    when "rejected", "cancelled", "withdrawn" then "smb-badge smb-badge--muted"
    else "smb-badge smb-badge--slate"
    end
  end

  def user_avatar(user, size: :md)
    palette = %w[brand sky emerald amber slate]
    tone = palette[user.id.to_i % palette.length]
    content_tag(:span, user.initials, class: "smb-avatar smb-avatar--#{size} smb-avatar--#{tone}", "aria-hidden": "true")
  end

  def render_stars(rating)
    score = rating.to_f.round
    stars = (1..5).map do |i|
      css = i <= score ? "fas fa-star smb-star-filled" : "far fa-star smb-star-empty"
      content_tag(:i, "", class: css, "aria-hidden": "true")
    end
    label = content_tag(:span, "#{rating} out of 5 stars", class: "visually-hidden")
    content_tag(:span, safe_join(stars + [label]), class: "d-inline-flex align-items-center gap-1")
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
    when ShippingRequest
      shipping_request_path(notification.notifiable)
    when ShipmentTracking
      shipment_tracking_path(notification.notifiable)
    when Conversation
      conversation_path(notification.notifiable)
    else
      notifications_path
    end
  end
end
