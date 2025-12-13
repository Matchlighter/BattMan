class AddScanHookToScanner < ActiveRecord::Migration[8.1]
  def change
    add_column :scanners, :scan_hook, :jsonb, null: true
  end
end
