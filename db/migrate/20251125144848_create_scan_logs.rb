class CreateScanLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :scan_logs do |t|
      t.references :scanner, null: false, foreign_key: true, type: :string
      t.references :object, polymorphic: true, null: true, type: :string
      t.text :payload
      t.string :status
      t.string :message

      t.timestamps
    end
  end
end
