class CreateThings < ActiveRecord::Migration[8.1]
  def change
    create_table :things, id: :string do |t|
      t.column :tags, :jsonb, default: {}
      t.column :own_tags, :jsonb, default: {}

      t.timestamps
    end
  end
end
