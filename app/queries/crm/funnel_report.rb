# frozen_string_literal: true

module Crm
  # Aggregates the pipeline by *current* stage.
  #
  # The naive version of this report groups `deal_histories` by stage, which
  # counts a deal once per stage it has ever been in. This one resolves each
  # deal's latest history row first (one LATERAL join, see Deal.with_current_stage)
  # so every deal is counted exactly once, in exactly one stage.
  class FunnelReport
    Stage = Struct.new(:name, :deal_count, :probability_sum, keyword_init: true) do
      def average_probability
        return 0.0 if deal_count.zero?

        (probability_sum.to_f / deal_count).round(1)
      end

      # Deals this stage is "worth" if every probability plays out as stated.
      def expected_deals = (probability_sum.to_f / 100).round(1)
    end

    def initialize(scope: Deal.all)
      @scope = scope
    end

    # Every known stage, in funnel order, including stages with no deals.
    def stages
      @stages ||= DealHistory.stage_names.map do |name|
        totals.fetch(name) { Stage.new(name: name, deal_count: 0, probability_sum: 0) }
      end
    end

    def stage(name) = stages.find { |s| s.name == name }

    def open_stages = stages.select { |s| DealHistory::OPEN_STAGES.include?(s.name) }

    def total_deals = stages.sum(&:deal_count) + unstaged_deals

    # Deals that exist but have never been given a stage. Surfaced rather than
    # quietly folded into "Lead".
    def unstaged_deals
      @unstaged_deals ||= totals_by_stage[nil].to_i
    end

    def open_deals = open_stages.sum(&:deal_count)
    def won_deals = stage(DealHistory::WON_STAGE).deal_count
    def lost_deals = stage(DealHistory::LOST_STAGE).deal_count
    def expected_open_deals = open_stages.sum(&:expected_deals).round(1)

    # Share of *decided* deals that were won. Undecided deals are excluded so the
    # figure does not drift downwards simply because the pipeline is growing.
    def win_rate
      decided = won_deals + lost_deals
      return 0.0 if decided.zero?

      ((won_deals.to_f / decided) * 100).round(1)
    end

    # Percentage of the widest stage, for drawing the funnel bars.
    def relative_width(stage)
      widest = stages.map(&:deal_count).max.to_i
      return 0 if widest.zero?

      ((stage.deal_count.to_f / widest) * 100).round(1)
    end

    private

    def totals
      @totals ||= totals_by_stage.filter_map do |stage_value, count|
        next if stage_value.nil?

        name = DealHistory.stages.key(stage_value)
        [name, Stage.new(name: name, deal_count: count, probability_sum: probability_sums[stage_value].to_i)]
      end.to_h
    end

    def aggregates
      @aggregates ||= @scope
                      .with_current_stage
                      .unscope(:select, :order)
                      .select('latest_history.stage AS current_stage_value',
                              'COUNT(deals.id) AS deal_count',
                              'COALESCE(SUM(deals.probability), 0) AS probability_sum')
                      .group('latest_history.stage')
                      .map { |row| [row[:current_stage_value], row[:deal_count], row[:probability_sum]] }
    end

    def totals_by_stage
      @totals_by_stage ||= aggregates.to_h { |stage, count, _sum| [stage, count] }
    end

    def probability_sums
      @probability_sums ||= aggregates.to_h { |stage, _count, sum| [stage, sum] }
    end
  end
end
