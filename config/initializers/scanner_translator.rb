class ScannerTranslator
  ENDPOINTS = {}

  HANDLERS = []
  HANDLERS_BY_MODEL = {}

  def self.define!(*args, **kwargs, &block)
    new(*args, **kwargs, &block)
  end

  def self.process_http_request(request)
    # Find matching handlers
    ENDPOINTS[:http]&.each do |subpath, handler|
      if request.path.start_with?("/#{subpath}")
        handler.call(request)
      end
    rescue => err
      Rails.logger.error("Error processing HTTP request for #{request.path}: #{err.message}")
    end
  end

  def self.process_mqtt_message(topic, message)
    # Find matching handler (accepting MQTT wildcards)
    ENDPOINTS[:mqtt]&.each do |subscribed_topic, handler|
      if MQTT::Match.match?(subscribed_topic, topic)
        handler.call(topic, message)
      end
    rescue => err
      Rails.logger.error("Error processing HTTP request for #{request.path}: #{err.message}")
    end
  end

  attr_reader :options, :handled_models, :endpoints

  def initialize(source, **options, &block)
    @source = source
    @handled_models = []
    @endpoints = {}
    @options = options

    HANDLERS << self
    instance_eval(&block)
  end

  def url_base
    Pathname.new(@source).dirname.relative_path_from(TRANSLATOR_BASEPATH).to_s
  end

  def handles_models(models)
    @handled_models.append(*Array(models))
    HANDLERS_BY_MODEL.merge!(Array(models).map { |m| [m, self] }.to_h)
  end

  def listen_http(subpath, &block)
    add_endpoint("http", subpath, &block)
  end

  def listen_mqtt(topic, &block)
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
    ENDPOINTS[type][identifier] = block
    @endpoints[type] ||= {}
    @endpoints[type][identifier] = block
  end
end

TRANSLATOR_BASEPATH = Rails.root.join("lib/translators/")

Dir.glob(File.join(TRANSLATOR_BASEPATH, "**/*.rb")).each do |file|
  ScannerTranslator.define!(
    file,
  ) do
    instance_eval(File.read(file), file)
  end
rescue LoadError => e
  Rails.logger.error("Error loading translator #{file}: #{e.message}")
end
