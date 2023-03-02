# frozen_string_literal: true

# A deal is one contact's opportunity at one company. Its position in the funnel
# is never stored on the deal itself: it is derived from the most recent
# DealHistory row, so the whole stage progression stays auditable.
class Deal < ApplicationRecord
  PROBABILITY_RANGE = (0..100)

  belongs_to :user, optional: true
  belongs_to :company, optional: true
  has_many :deal_histories, -> { chronological }, dependent: :destroy, inverse_of: :deal

  validates :probability,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: PROBABILITY_RANGE.first,
              less_than_or_equal_to: PROBABILITY_RANGE.last
            }

  scope :recent, -> { order(created_at: :desc, id: :desc) }

  # Attaches the current stage to each row with a single LATERAL join instead of
  # one `deal_histories.last` query per deal. See README "Design notes".
  scope :with_current_stage, lambda {
    select('deals.*, latest_history.stage AS current_stage_value')
      .joins(<<~SQL.squish)
        LEFT JOIN LATERAL (
          SELECT dh.stage
          FROM deal_histories dh
          WHERE dh.deal_id = deals.id
          ORDER BY dh.created_at DESC, dh.id DESC
          LIMIT 1
        ) latest_history ON TRUE
      SQL
  }

  scope :for_index, -> { with_current_stage.includes(:user, :company).recent }

  # Stage name (e.g. "Diligence") of the most recent history entry, or nil when
  # the deal has never been staged. Uses the pre-joined value when the record
  # came from `with_current_stage`, otherwise falls back to a single query.
  def current_deal_stage
    if has_attribute?(:current_stage_value)
      raw = self[:current_stage_value]
      raw.nil? ? nil : DealHistory.stages.key(raw)
    else
      deal_histories.reorder(created_at: :desc, id: :desc).limit(1).pick(:stage)
    end
  end

  def open?
    DealHistory::OPEN_STAGES.include?(current_deal_stage)
  end
end
