class AddIndexTokaiLends < ActiveRecord::Migration[5.1]
  def change
    add_index :tokai_lends, [:isbn], unique: true
  end
end
