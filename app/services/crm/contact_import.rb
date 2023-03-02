# frozen_string_literal: true

module Crm
  # Loads contacts, companies, deals and stage history from any import source
  # (see Crm::Import::CsvSource) into the CRM.
  #
  # Two correctness rules the original inline seed script got wrong:
  #
  #   * A contact is identified by e-mail alone, so repeated e-mails become ONE
  #     contact and ONE deal (see Crm::Import::Contact).
  #   * Repeated rows collapse only when the stage is unchanged, so a genuine
  #     Lead -> Contacted move survives as two history entries.
  #
  # Everything is written with batched `insert_all` inside one transaction. The
  # row-at-a-time `find_or_create_by!` version issued about three round trips per
  # line: 8,240 queries for the bundled 1,000-row export, against 8 here.
  class ContactImport
    BATCH_SIZE = 1_000

    def self.call(...) = new(...).call

    def initialize(source:, logger: Rails.logger, now: Time.current)
      @source = source
      @logger = logger
      @now = now
    end

    def call
      rows = @source.each_row.to_a
      valid, invalid = rows.partition(&:valid?)
      contacts = valid.group_by(&:email).values.map { |group| Import::Contact.merge(group) }
      result = blank_result(rows, invalid, merged: valid.size - contacts.size)

      ApplicationRecord.transaction do
        company_ids = upsert_companies(contacts, result)
        user_ids = upsert_contacts(contacts, company_ids, result)
        deal_ids = upsert_deals(contacts, company_ids, user_ids, result)
        append_stage_history(contacts, deal_ids, result)
      end

      @logger&.info("[#{self.class.name}] #{@source.name}: #{result}")
      result
    end

    private

    def blank_result(rows, invalid, merged:)
      Import::Result.new(
        rows_read: rows.size,
        rows_rejected: invalid.size,
        duplicate_rows_merged: merged,
        probabilities_clamped: rows.count(&:probability_clamped?),
        companies_created: 0, contacts_created: 0, contacts_updated: 0,
        deals_created: 0, stage_entries_created: 0,
        rejections: invalid.map do |row|
          Import::Rejection.new(line_number: row.line_number, email: row.email, errors: row.errors)
        end
      )
    end

    # => { "Initech" => 12, ... }
    def upsert_companies(contacts, result)
      names = contacts.filter_map(&:company).uniq
      ids = names.empty? ? {} : Company.where(name: names).pluck(:name, :id).to_h

      (names - ids.keys).each_slice(BATCH_SIZE) do |batch|
        rows = batch.map { |name| { name: name, created_at: @now, updated_at: @now } }
        Company.insert_all(rows, returning: %w[id name]).each { |row| ids[row['name']] = row['id'] }
        result.companies_created += batch.size
      end

      ids
    end

    # => { "ada@example.com" => 34, ... }
    def upsert_contacts(contacts, company_ids, result)
      ids = User.where(email: contacts.map(&:email)).pluck(:email, :id).to_h
      result.contacts_updated = ids.size
      result.contacts_created = contacts.size - ids.size

      contacts.each_slice(BATCH_SIZE) do |batch|
        rows = batch.map { |c| c.user_attributes(company_id: company_ids[c.company], at: @now) }
        User.upsert_all(rows, unique_by: :index_users_on_email, returning: %w[id email])
            .each { |row| ids[row['email']] = row['id'] }
      end

      ids
    end

    # => { <Contact> => deal_id }
    def upsert_deals(contacts, company_ids, user_ids, result)
      keys = contacts.index_with { |c| [user_ids[c.email], company_ids[c.company]] }
      ids = existing_deal_ids(keys.values)

      contacts.reject { |contact| ids.key?(keys[contact]) }.each_slice(BATCH_SIZE) do |batch|
        insert_deals(batch, keys).each { |row| ids[[row['user_id'], row['company_id']]] = row['id'] }
        result.deals_created += batch.size
      end

      keys.transform_values { |key| ids[key] }
    end

    def insert_deals(contacts, keys)
      rows = contacts.map do |contact|
        user_id, company_id = keys[contact]
        contact.deal_attributes(user_id: user_id, company_id: company_id, at: @now)
      end
      Deal.insert_all(rows, returning: %w[id user_id company_id])
    end

    def existing_deal_ids(keys)
      user_ids = keys.filter_map(&:first)
      return {} if user_ids.empty?

      Deal.where(user_id: user_ids).pluck(:user_id, :company_id, :id)
          .each_with_object({}) { |(user_id, company_id, id), memo| memo[[user_id, company_id]] ||= id }
    end

    def append_stage_history(contacts, deal_ids, result)
      recorded = recorded_stages(deal_ids.values.compact)

      rows = contacts.flat_map { |contact| history_rows(contact, deal_ids[contact], recorded) }
      rows.each_slice(BATCH_SIZE) do |batch|
        DealHistory.insert_all(batch)
        result.stage_entries_created += batch.size
      end
    end

    def recorded_stages(deal_ids)
      return {} if deal_ids.empty?

      DealHistory.where(deal_id: deal_ids).chronological.pluck(:deal_id, :stage)
                 .group_by(&:first).transform_values { |pairs| pairs.map(&:last) }
    end

    # History timestamps are spaced a second apart so the ordering of a
    # progression imported in one pass is unambiguous.
    def history_rows(contact, deal_id, recorded)
      return [] if deal_id.nil?

      seen = recorded.fetch(deal_id, [])
      contact.stages_after(seen).each_with_index.map do |stage, offset|
        at = @now + ((seen.size + offset) * 1.second)
        { deal_id: deal_id, stage: DealHistory.stages.fetch(stage), created_at: at, updated_at: at }
      end
    end
  end
end
