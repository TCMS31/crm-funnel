# frozen_string_literal: true

# Migration to create Deal model
class CreateDeal < ActiveRecord::Migration[7.0]
  def change
    create_table :deals do |t|
      t.references :user, foreign_key: true
      t.references :company, foreign_key: true
      t.integer :probability, default: 0, null: false

      t.timestamps
    end
  end
end
