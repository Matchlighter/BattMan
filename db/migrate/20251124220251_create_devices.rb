class CreateDevices < ActiveRecord::Migration[8.1]
  def change
    create_table :devices, id: false do |t|
      t.string :id, primary_key: true
      t.string :human_name
      t.timestamps
    end
  end
end
