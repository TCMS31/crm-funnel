# frozen_string_literal: true

module Crm
  module Import
    Rejection = Struct.new(:line_number, :email, :errors, keyword_init: true)

    # What an import actually did. Returned rather than logged so callers (the
    # seed task, specs, a future admin screen) can assert on it.
    Result = Struct.new(
      :rows_read, :rows_rejected, :duplicate_rows_merged, :probabilities_clamped,
      :companies_created, :contacts_created, :contacts_updated, :deals_created,
      :stage_entries_created, :rejections,
      keyword_init: true
    ) do
      def to_s
        format(
          'read %<rows_read>d rows -> %<contacts_created>d new contacts, %<companies_created>d new companies, ' \
          '%<deals_created>d new deals, %<stage_entries_created>d stage entries ' \
          '(%<duplicate_rows_merged>d duplicate rows merged, %<probabilities_clamped>d probabilities clamped, ' \
          '%<rows_rejected>d rows rejected)',
          to_h
        )
      end
    end
  end
end
