class CreateTokaiLends < ActiveRecord::Migration[5.1]
  def change
    create_table :tokai_lends do |t|
      t.date :date
      t.text :location
      t.text :title
      t.integer :isbn

      t.timestamps
    end
  end
end
