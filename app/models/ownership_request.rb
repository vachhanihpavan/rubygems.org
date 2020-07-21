class OwnershipRequest < ApplicationRecord
  belongs_to :rubygem
  belongs_to :user
  belongs_to :ownership_call, optional: true
  belongs_to :approver, class_name: "User", optional: true

  validates :rubygem_id, :user_id, :status, presence: true
  validates :note, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }
  validates :user_id, uniqueness: { scope: :rubygem_id, conditions: -> { opened } }

  delegate :name, to: :user, prefix: true

  enum status: { opened: 0, approved: 1, closed: 2 }

  def approve(approver)
    return false unless approver

    update(status: :approved, approver: approver)
    Ownership.create_confirmed(rubygem, user, approver)
  end

  def can_close?(user)
    self.user == user || rubygem.owned_by?(user)
  end
end
