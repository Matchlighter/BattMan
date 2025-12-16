
handles_models(["Netum/DS2800/MQTT", "Netum/DS2800/HTTP"])

listen_mqtt("netum/scan") do |topic, message|
  message = JSON.parse(message.gsub(/[\r]/, ""))
  id = message["id"]
  Scanner.process_scan_event!(id, message["msg"])
  sleep(0.2)
  $mqtt_client.publish("netum/#{id}/cmd", { ply: 1, msg: "BEEP" }.to_json)
rescue Scanner::ScanError
  puts "A"
  sleep(0.2)
  $mqtt_client.publish("netum/#{id}/cmd", { ply: 2, msg: "BEEP" }.to_json)
rescue StandardError => e
  sleep(0.2)
  $mqtt_client.publish("netum/#{id}/cmd", { ply: 3, msg: "BEEP" }.to_json)
end

# listen_http("netum") do |request|
#   # TODO
# end
