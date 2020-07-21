class OwnershipCall < ApplicationRecord
  belongs_to :rubygem
  belongs_to :user
  has_many :ownership_requests, dependent: :destroy

  validates :note, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }
  validates :email, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }, format: { with: URI::MailTo::EMAIL_REGEXP }, presence: true
  validates :rubygem_id, :user_id, :status, presence: true
  validates :rubygem_id, uniqueness: { conditions: -> { opened } }

  delegate :name, to: :rubygem, prefix: true
  delegate :display_handle, to: :user, prefix: true

  enum status: { opened: true, closed: false }

  def close
    ownership_requests.opened.update_all(status: :closed)
    update(status: :closed)
  end

  def applied_by?(user)
    ownership_requests.where(user: user).exists?
  end
end
