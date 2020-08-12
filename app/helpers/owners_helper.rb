module OwnersHelper
  def owner_i18n_key(owner, user)
    owner.id == user.id ? "self" : "others"
  end

  def confirmation_status(ownership)
    if ownership.confirmed?
      image_tag("/images/check.svg") + "Confirmed"
    else
      image_tag("/images/clock.svg") + "Pending"
    end
  end

  def mfa_status(user)
    if user.mfa_level == "disabled"
      image_tag("/images/x.svg")
    else
      image_tag("/images/check.svg")
    end
  end

  def sanitize_note(text)
    options = RDoc::Options.new
    options.pipe = true
    simple_format RDoc::Markup.new.convert(text, RDoc::Markup::ToHtml.new(options))
  end
end
