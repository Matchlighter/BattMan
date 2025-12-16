module ScannerTranslator
  extend self
  ENDPOINTS = {}

  def define!(&block)
    handler = Handler.new
    handler.instance_eval(&block)
  end

  def process_http_request(request)
    # Find matching handlers
    ENDPOINTS[:http]&.each do |subpath, handler|
      if request.path.start_with?("/#{subpath}")
        handler.call(request)
      end
    rescue => err
      Rails.logger.error("Error processing HTTP request for #{request.path}: #{err.message}")
    end
  end

  def process_mqtt_message(topic, message)
    # Find matching handler (accepting MQTT wildcards)
    ENDPOINTS[:mqtt]&.each do |subscribed_topic, handler|
      if MQTT::Match.match?(subscribed_topic, topic)
        handler.call(topic, message)
      end
    rescue => err
      Rails.logger.error("Error processing HTTP request for #{request.path}: #{err.message}")
    end
  end

  class Handler
    def handle_http(subpath, &block)
      add_endpoint("http", subpath, &block)
    end

    def handle_mqtt(topic, &block)
      add_endpoint("mqtt", topic, &block)
      full_topic = "$share/battman-ingress/#{topic}"
      ActiveSupport.on_load(:mqtt_client) do
        Rails.logger.info("Subscribing to MQTT shared topic: #{full_topic}")
        $mqtt_client.subscribe(full_topic)
      end
    end

    private

    def add_endpoint(type, identifier, &block)
      type = type.to_sym
      ENDPOINTS[type] ||= {}
      # raise "Endpoint #{key} already defined" if ENDPOINTS[type].key?(identifier)
      ENDPOINTS[type][identifier] = block
    end
  end
end

Dir.glob(Rails.root.join("lib/translators/**/*.rb")).each do |file|
  ScannerTranslator.define! do
    instance_eval(File.read(file), file)
  end
rescue LoadError => e
  Rails.logger.error("Error loading translator #{file}: #{e.message}")
end
