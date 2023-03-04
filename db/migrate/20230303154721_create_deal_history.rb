# frozen_string_literal: true

# Migration to create DealHistory model
class CreateDealHistory < ActiveRecord::Migration[7.0]
  def change
    create_table :deal_histories do |t|
      t.references :deal, foreign_key: true, null: false
      t.integer :stage, default: 0

      t.timestamps
    end
  end
end
