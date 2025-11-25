class Scanner < ApplicationRecord
  def beep!(count = 1)
    $mqtt_client.publish("netum/#{id}/cmd", { ply: count, msg: "BEEP" }.to_json)
  end
end
