module MQTT
  class Match
    def self.match?(pattern, topic)
      pattern_parts = pattern.split('/')
      topic_parts = topic.split('/')

      match_parts(pattern_parts, topic_parts)
    end

    private

    def self.match_parts(pattern_parts, topic_parts, pattern_idx = 0, topic_idx = 0)
      # Both exhausted - match
      return true if pattern_idx >= pattern_parts.length && topic_idx >= topic_parts.length

      # Pattern exhausted but topic remains - no match
      return false if pattern_idx >= pattern_parts.length

      # Topic exhausted but pattern remains - only match if rest of pattern is all #
      return pattern_parts[pattern_idx..].all? { |p| p == '#' } if topic_idx >= topic_parts.length

      pattern_part = pattern_parts[pattern_idx]

      case pattern_part
      when '#'
        # # matches zero or more levels - try matching rest of pattern at each position
        (topic_idx..topic_parts.length).any? do |i|
          match_parts(pattern_parts, topic_parts, pattern_idx + 1, i)
        end
      when '+'
        # + matches exactly one level
        match_parts(pattern_parts, topic_parts, pattern_idx + 1, topic_idx + 1)
      else
        # Literal match required
        return false if pattern_part != topic_parts[topic_idx]
        match_parts(pattern_parts, topic_parts, pattern_idx + 1, topic_idx + 1)
      end
    end
  end
end

if defined?(::Rails::Server)
  mqtt_url = read_setting("mqtt.url")

  Thread.new do
    loop do
      puts "Connecting to MQTT broker"
      $mqtt_client = MQTT::Client.connect(mqtt_url)

      ActiveSupport.run_load_hooks(:mqtt_client)

      $mqtt_client.get do |topic, message|
        ScannerTranslator.perform_later.process_mqtt_message(topic, message)
      end
    rescue MQTT::ProtocolException => err
      Rails.logger.error("MQTT listener error: #{err.message}: \n #{err.backtrace.join("\n")}")
      sleep 1
    end
  end
end
