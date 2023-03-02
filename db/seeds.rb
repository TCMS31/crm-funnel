# frozen_string_literal: true

# Loads the bundled contact export into the CRM. Idempotent: re-running it adds
# nothing, because Crm::ContactImport keys contacts on e-mail and only appends
# stage history that actually extends a deal.
#
#   CRM_IMPORT_CSV=path/to/export.csv bin/rails db:seed

path = ENV.fetch('CRM_IMPORT_CSV') { Rails.root.join('crm_data.csv').to_s }

result = Crm::ContactImport.call(source: Crm::Import::CsvSource.new(path))

puts "Imported #{path}"
puts "  #{result}"
result.rejections.first(10).each do |rejection|
  puts "  line #{rejection.line_number}: #{rejection.errors.join('; ')}"
end
puts "  ...and #{result.rejections.size - 10} more rejected rows" if result.rejections.size > 10
