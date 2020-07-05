class Ownership < ApplicationRecord
  belongs_to :rubygem
  belongs_to :user
  belongs_to :authorizer, class_name: "User", optional: true

  validates :user_id, uniqueness: { scope: :rubygem_id }

  before_create :generate_confirmation_token

  scope :confirmed, -> { where("confirmed_at IS NOT NULL") }
  scope :unconfirmed, -> { where("confirmed_at IS NULL") }

  def self.by_indexed_gem_name
    select("ownerships.*, rubygems.name")
      .left_joins(rubygem: :versions)
      .where(versions: { indexed: true })
      .distinct
      .order("rubygems.name ASC")
  end

  def valid_confirmation_token?
    token_expires_at > Time.zone.now
  end

  def generate_confirmation_token
    self.token = SecureRandom.hex(20).encode("UTF-8")
    self.token_expires_at = Time.zone.now + Gemcutter::OWNERSHIP_TOKEN_EXPIRES_AFTER
  end

  def confirm_ownership!
    update(confirmed_at: Time.current)
  end

  def confirmed?
    confirmed_at.present?
  end

  def unconfirmed?
    !confirmed?
  end

  def expired?
    !confirmed? && !valid_confirmation_token?
  end

  def notify_owner_removed
    rubygem.notifiable_owners.each do |notified_user|
      Mailer.delay.owner_removed(user_id, notified_user.id, rubygem_id)
    end
  end

  def notify_owner_added
    rubygem.notifiable_owners.each do |notified_user|
      Mailer.delay.owner_added(user_id, notified_user.id, rubygem_id)
    end
  end

  def confirm_and_notify
    confirm_ownership! && notify_owner_added
  end

  def safe_destroy
    return destroy if unconfirmed?
    rubygem.owners.many? && destroy
  end

  def destroy_and_notify
    if safe_destroy
      Mailer.delay.owner_removed(user_id, user_id, rubygem_id)
      notify_owner_removed
    else
      false
    end
  end
end
