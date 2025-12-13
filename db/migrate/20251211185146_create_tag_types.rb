class CreateTagTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :tag_types, id: :string do |t|
      t.boolean :inheritable
      t.string :default
      t.string :typing

      # t.string :indexing_strategy # TODO ?

      t.timestamps
    end
  end
end
