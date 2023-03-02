# frozen_string_literal: true

# One immutable entry in a deal's stage progression. Rows are append-only: a
# deal moves forward by gaining a history row, never by editing an old one.
class DealHistory < ApplicationRecord
  STAGES = { Lead: 0, Contacted: 1, Diligence: 2, Closed: 3, Rejected: 4 }.freeze
  OPEN_STAGES = %w[Lead Contacted Diligence].freeze
  WON_STAGE = 'Closed'
  LOST_STAGE = 'Rejected'

  belongs_to :deal

  # `validate: true` turns an unknown stage from a form into a validation
  # error instead of the ArgumentError (and 500) a plain enum raises.
  enum :stage, STAGES, validate: true

  validates :stage, presence: true

  scope :chronological, -> { order(created_at: :asc, id: :asc) }

  # Bounded and preloaded: the dashboard shows a fixed window of activity, never
  # the whole table.
  scope :latest_moves, lambda { |limit|
    includes(deal: %i[user company]).order(created_at: :desc, id: :desc).limit(limit)
  }

  def self.stage_names
    STAGES.keys.map(&:to_s)
  end

  def terminal?
    [WON_STAGE, LOST_STAGE].include?(stage)
  end
end
