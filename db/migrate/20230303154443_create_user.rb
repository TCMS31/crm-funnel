# frozen_string_literal: true

# Migration to create users table
class CreateUser < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :first_name, null: false, default: ''
      t.string :last_name, null: false, default: ''
      t.string :email, null: false
      t.string :phone_number
      t.references :company, foreign_key: true, null: true
      t.index :email, unique: true

      t.timestamps
    end
  end
end
