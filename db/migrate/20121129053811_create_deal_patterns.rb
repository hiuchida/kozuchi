# -*- encoding : utf-8 -*-
class CreateDealPatterns < ActiveRecord::Migration[5.0]
  def up
    create_table :deal_patterns do |t|
      t.integer :user_id, :null => false
      t.string :code, :limit => 10 # NULL 可
      t.string :name, :null => false, :default => ''

      t.timestamps
    end
    execute "ALTER TABLE deal_patterns MODIFY code varchar(10) BINARY;"
    add_index :deal_patterns, [:user_id, :code], :unique => true
  end

  def down
    remove_index :deal_patterns, [:user_id, :code]
    drop_table :deal_patterns
  end
end
