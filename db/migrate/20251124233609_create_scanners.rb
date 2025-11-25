class CreateScanners < ActiveRecord::Migration[8.1]
  def change
    create_table :scanners, id: false do |t|
      t.string :id, primary_key: true
      t.column :state, :jsonb, default: {}
      t.timestamps
    end
  end
end
