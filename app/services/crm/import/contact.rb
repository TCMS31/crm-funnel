# frozen_string_literal: true

module Crm
  module Import
    # One person, assembled from every inbound row that shares their e-mail.
    #
    # E-mail is the natural key: rows repeating an e-mail describe the same
    # contact, so their details are combined rather than inserted twice. This is
    # where the "19 phantom company-less deals" bug was: a later row that left
    # `company` blank used to look like a different deal.
    class Contact
      attr_reader :email, :first_name, :last_name, :phone, :company, :probability, :stages

      # rows: every ContactRow sharing one e-mail, in file order.
      def self.merge(rows)
        new(
          email: rows.first.email,
          first_name: first_present(rows, :first_name),
          last_name: first_present(rows, :last_name),
          phone: first_present(rows, :phone),
          company: first_present(rows, :company),
          probability: rows.last.probability,
          # Collapses Lead -> Lead, keeps Lead -> Contacted.
          stages: rows.map(&:stage).chunk_while { |a, b| a == b }.map(&:first)
        )
      end

      def self.first_present(rows, attribute)
        rows.filter_map { |row| row.public_send(attribute) }.first
      end
      private_class_method :first_present

      def initialize(email:, first_name:, last_name:, phone:, company:, probability:, stages:)
        @email = email
        @first_name = first_name
        @last_name = last_name
        @phone = phone
        @company = company
        @probability = probability
        @stages = stages
      end

      def user_attributes(company_id:, at:)
        { email: email, first_name: first_name, last_name: last_name, phone_number: phone,
          company_id: company_id, created_at: at, updated_at: at }
      end

      def deal_attributes(user_id:, company_id:, at:)
        { user_id: user_id, company_id: company_id, probability: probability,
          created_at: at, updated_at: at }
      end

      # The stages this contact adds on top of what the deal already recorded.
      # Returns [] when the import has already been run, which is what makes the
      # whole import idempotent.
      def stages_after(recorded)
        cursor = 0
        recorded.each { |stage| cursor += 1 if stages[cursor] == stage }
        stages[cursor..] || []
      end
    end
  end
end
