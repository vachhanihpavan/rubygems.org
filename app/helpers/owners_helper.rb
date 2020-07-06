module OwnersHelper
  def confirmation_status(ownership)
    if ownership.confirmed?
      content_tag(:span, "Confirmed", data: { icon: "✔ " }, class: "ownership__green")
    elsif ownership.expired?
      content_tag(:span, "Expired", data: { icon: "✗ " }, class: "ownership__red")
    else
      content_tag(:span, "Pending", data: { icon: "⧖ " }, class: "ownership__blue")
    end
  end

  def mfa_status(user)
    if user.mfa_level == "disabled"
      content_tag(:span, "Disabled", data: { icon: "🔓 " }, class: "ownership__red")
    else
      content_tag(:span, "Enabled", data: { icon: "🔒 " }, class: "ownership__green")
    end
  end
end
