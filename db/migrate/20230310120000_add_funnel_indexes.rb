# frozen_string_literal: true

# Indexes for the three access patterns the app actually has:
#   1. "latest history row for this deal" (the funnel's current-stage lookup),
#   2. "most recent records first" (every index page),
#   3. "one company per name" (the CSV import's natural key).
class AddFunnelIndexes < ActiveRecord::Migration[7.0]
  def change
    add_index :deal_histories, %i[deal_id created_at id],
              name: 'index_deal_histories_on_deal_and_recency'

    add_index :deals, %i[created_at id], order: { created_at: :desc, id: :desc },
                                         name: 'index_deals_on_recency'
    add_index :users, %i[created_at id], order: { created_at: :desc, id: :desc },
                                         name: 'index_users_on_recency'
    add_index :companies, %i[created_at id], order: { created_at: :desc, id: :desc },
                                             name: 'index_companies_on_recency'

    add_index :companies, 'lower(name)', unique: true, name: 'index_companies_on_lower_name'
  end
end
