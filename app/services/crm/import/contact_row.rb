# frozen_string_literal: true

module Crm
  module Import
    # A single inbound contact record, normalised and validated independently of
    # where it came from. Sources (see CsvSource) yield these; ContactImport
    # consumes them and never touches a raw CSV row.
    class ContactRow
      ATTRIBUTES = %i[first_name last_name email phone company stage probability].freeze

      attr_reader(*ATTRIBUTES, :line_number, :probability_clamped)

      def initialize(line_number:, first_name: nil, last_name: nil, email: nil,
                     phone: nil, company: nil, stage: nil, probability: nil)
        @line_number = line_number
        @first_name = squish(first_name)
        @last_name = squish(last_name)
        @email = squish(email)&.downcase
        @phone = squish(phone)
        @company = squish(company)
        @stage = normalize_stage(stage)
        @probability, @probability_clamped = normalize_probability(probability)
      end

      def probability_clamped? = probability_clamped

      def errors
        @errors ||= [email_error, name_error, stage_error].compact.freeze
      end

      def valid? = errors.empty?

      private

      def email_error
        return 'email is blank' if email.blank?
        return if email.match?(::User::EMAIL_REGEX)

        "email #{email.inspect} is malformed"
      end

      def name_error
        missing = { first_name: first_name, last_name: last_name }.select { |_, value| value.blank? }.keys
        "#{missing.join(' and ')} is blank" if missing.any?
      end

      def stage_error
        'stage is not a known funnel stage' if stage.nil?
      end

      def squish(value)
        value.is_a?(String) ? value.strip.squeeze(' ').presence : value.presence
      end

      # Accepts "diligence", "Diligence", " DILIGENCE " — returns the canonical
      # name or nil so the row can be reported as invalid rather than guessed at.
      def normalize_stage(value)
        return nil if value.blank?

        ::DealHistory.stage_names.find { |name| name.casecmp?(value.to_s.strip) }
      end

      # The source data contains probabilities above 100. They are clamped rather
      # than dropped, but the clamp is counted and reported instead of silent.
      def normalize_probability(value)
        number = value.to_s.strip
        return [0, false] if number.blank?

        integer = Integer(number, exception: false) || Float(number, exception: false)&.round || 0
        clamped = integer.clamp(::Deal::PROBABILITY_RANGE.first, ::Deal::PROBABILITY_RANGE.last)
        [clamped, clamped != integer]
      end
    end
  end
end
