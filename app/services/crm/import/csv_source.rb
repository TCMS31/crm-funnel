# frozen_string_literal: true

require 'csv'

module Crm
  module Import
    # Reads contacts from a headed CSV file.
    #
    # This is the extensibility seam: ContactImport depends only on `#each_row`
    # yielding ContactRow objects, so a HubspotSource or SalesforceSource can be
    # dropped in without the import logic changing. See README "Extensibility".
    class CsvSource
      REQUIRED_HEADERS = %w[first_name last_name email stage company probability].freeze

      class MissingHeadersError < StandardError; end

      def initialize(path)
        @path = path
      end

      def name = "csv:#{File.basename(@path)}"

      def each_row
        return enum_for(:each_row) unless block_given?

        table = CSV.read(@path, headers: true)
        assert_headers!(table.headers)

        table.each.with_index(2) do |row, line_number|
          yield ContactRow.new(
            line_number: line_number,
            first_name: row['first_name'],
            last_name: row['last_name'],
            email: row['email'],
            phone: row['phone'],
            company: row['company'],
            stage: row['stage'],
            probability: row['probability']
          )
        end
      end

      private

      def assert_headers!(headers)
        missing = REQUIRED_HEADERS - headers.compact.map(&:to_s)
        return if missing.empty?

        raise MissingHeadersError, "#{@path} is missing required column(s): #{missing.join(', ')}"
      end
    end
  end
end
