# frozen_string_literal: true

# A contact in the CRM. Named `User` by the original schema; it models the
# person on the other side of a deal, not an authenticated account.
class User < ApplicationRecord
  EMAIL_REGEX = /\A[^@\s]+@[^@\s]+\.[^@\s]{2,}\z/

  belongs_to :company, optional: true
  has_many :deals, dependent: :nullify

  validates :first_name, :last_name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: EMAIL_REGEX }

  scope :recent, -> { order(created_at: :desc, id: :desc) }

  # Emails are the import's natural key, so they are normalised on the way in
  # rather than at every call site that compares them.
  def email=(value)
    super(value.to_s.strip.downcase.presence)
  end

  def full_name
    "#{first_name} #{last_name}".strip
  end
end
