class CreateThings < ActiveRecord::Migration[8.1]
  def change
    create_table :things, id: :string do |t|
      t.column :tags, :jsonb, default: {}
      t.column :own_tags, :jsonb, default: {}

      # t.string :cached_ancestry, collation: 'C', null: false
      # t.index :cached_ancestry

      # t.string :cached_inheritance, collation: 'C', null: false
      # t.index :cached_inheritance

      t.timestamps
    end
  end
end
