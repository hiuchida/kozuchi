class RemoveUsesComplexDealFromPreferences < ActiveRecord::Migration[5.0]
  def up
    remove_column :preferences, :uses_complex_deal
  end

  def down
    add_column :preferences, :uses_complex_deal, :boolean, :default => false, :null => false
  end
end
