# frozen_string_literal: true

require 'csv'
require 'tempfile'

# Writes a throwaway CSV so import specs exercise the real Crm::Import::CsvSource
# (headers, parsing, normalisation) instead of a stubbed source.
module CsvFixture
  HEADERS = %w[first_name last_name email stage phone company probability].freeze

  def csv_source(rows, headers: HEADERS)
    file = Tempfile.new(['contacts', '.csv'])
    file.write(CSV.generate do |csv|
      csv << headers
      rows.each { |row| csv << headers.map { |h| row[h.to_sym] } }
    end)
    file.close
    @csv_fixtures = (@csv_fixtures || []) << file
    Crm::Import::CsvSource.new(file.path)
  end

  def contact_row(overrides = {})
    { first_name: 'Ada', last_name: 'Lovelace', email: 'ada@example.com', stage: 'Lead',
      phone: '555-0100', company: 'Analytical Engines', probability: '30' }.merge(overrides)
  end
end

RSpec.configure do |config|
  config.include CsvFixture
  config.after { (@csv_fixtures || []).each(&:unlink) }
end
