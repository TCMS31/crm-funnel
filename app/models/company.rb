# frozen_string_literal: true

# An organisation a contact belongs to. Companies are never deleted implicitly:
# their deals and users are detached so funnel history survives.
class Company < ApplicationRecord
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  has_many :deals, dependent: :nullify
  has_many :users, dependent: :nullify

  scope :recent, -> { order(created_at: :desc, id: :desc) }

  # Contact and deal totals for the index, as two correlated subqueries rather
  # than two extra queries per row.
  scope :with_counts, lambda {
    select('companies.*',
           '(SELECT COUNT(*) FROM users WHERE users.company_id = companies.id) AS users_count',
           '(SELECT COUNT(*) FROM deals WHERE deals.company_id = companies.id) AS deals_count')
  }

  def users_count = self[:users_count] || users.count
  def deals_count = self[:deals_count] || deals.count
end
