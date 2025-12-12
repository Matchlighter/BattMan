class Scanner < ApplicationRecord
  class ScanError < StandardError; end

  def self.process_scan_event!(scanner_id, payload)
    # TODO Check if the scanner ID has a hook
    #   If yes, send a message to the hook's channel and return
    #   If no, ScanLog.process_scan!
  end

  def self.add_translator(&block)
    handler = Handler.new
    handler.instance_eval(&block)
  end

  class Handler
    def handle_http(subpath, &block)
    end

    def handle_mqtt(topic, &block)
    end
  end
end
