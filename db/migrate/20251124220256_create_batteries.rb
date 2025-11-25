class CreateBatteries < ActiveRecord::Migration[8.1]
  def change
    create_table :batteries, id: false do |t|
      t.string :id, primary_key: true
      t.references :current_device, null: true, foreign_key: { to_table: :devices }, type: :string
      t.timestamps
    end
  end
end
