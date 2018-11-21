# -*- encoding : utf-8 -*-

class AddTypeToAccountEntries < ActiveRecord::Migration[5.0]
  def self.up
    add_column :account_entries, :type, :string
    execute "update account_entries inner join deals on deals.id = account_entries.deal_id set account_entries.type = deals.type;"
  end

  def self.down
    remove_column :account_entries, :type
  end
end
