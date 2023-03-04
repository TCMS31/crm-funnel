# frozen_string_literal: true

# One immutable entry in a deal's stage progression. Rows are append-only: a
# deal moves forward by gaining a history row, never by editing an old one.
class DealHistory < ApplicationRecord
  STAGES = { Lead: 0, Contacted: 1, Diligence: 2, Closed: 3, Rejected: 4 }.freeze
  OPEN_STAGES = %w[Lead Contacted Diligence].freeze
  WON_STAGE = 'Closed'
  LOST_STAGE = 'Rejected'

  belongs_to :deal

  enum stage: STAGES

  validates :stage, presence: true
  validate :stage_must_be_known

  # ActiveRecord's enum raises ArgumentError on an unknown value, which turns a
  # bad form submission into a 500. Capture it and report it as a validation
  # error instead, without loosening the enum itself.
  def stage=(value)
    @unknown_stage = nil
    super
  rescue ArgumentError
    @unknown_stage = value
    super(nil)
  end

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

  private

  def stage_must_be_known
    return if @unknown_stage.blank?

    errors.add(:stage, "#{@unknown_stage.inspect} is not one of #{self.class.stage_names.join(', ')}")
  end
end
