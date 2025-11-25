# TODO: This will not scale past 1 server instance

if defined?(::Rails::Server)
  mqtt_config = Rails.configuration.mqtt || Rails.application.credentials.mqtt
  mqtt_url = mqtt_config.url

  mqtt_url = read_setting("mqtt.url")
  client_id = read_setting("mqtt.client_id", "battman")
  topic = read_setting("mqtt.topic", "netum/scan")

  puts "Connecting to MQTT broker"
  $mqtt_client = MQTT::Client.connect(mqtt_url, client_id: client_id)

  Thread.new do
    puts "Starting MQTT listener on topic #{topic}"
    $mqtt_client.get(topic) do |topic,message|
      message = message.gsub(/[\r]/, "")
      ProcessScanEventJob.perform_later(message)
    end
  end
end
