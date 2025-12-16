
handles_models(["Generic/HTTP", "Generic/MQTT"])

listen_mqtt("battman/scan") do |topic, message|
  # TODO
end

listen_http("generic") do |request|
  # TODO
end
