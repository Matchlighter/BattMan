class Scanner < ApplicationRecord
  class ScanError < StandardError; end

  def self.process_scan_event!(scanner_id, payload)
    scanner = Scanner.find(scanner_id)

    if (m = /^BATTMAN:(.*)$/.match(payload))
      meta = m[1]

      # Tell the client Channel to subscribe to the scanner
      if meta.start_with?("CLIENT:")
        client_uid = meta.split(":")[1]
        ClientChannel.broadcast_to(client_uid, {
          type: "watch_scanner",
          scanner_id: scanner.id,
        })
      end
    elsif (client_uid = scanner.scan_hook).present?
      ClientChannel.broadcast_to(client_uid, {
        type: "scan",
        scanner_id: scanner.id,
        hooked: true,
        payload: payload,
      })
    else
      ScanLog.process_scan!(scanner, payload)
    end
  end

  def self.add_translator(&block)
    handler = Handler.new
    handler.instance_eval(&block)
  end

  def scan_hook
    h = attributes["scan_hook"]
    return unless h && h["exp"] < Time.now.to_i
    h["ch"]
  end

  def set_scan_hook(channel)
    update(scan_hook: { "ch" => channel, "exp" => (Time.now + 10.minutes).to_i })
  end

  def release_scan_hook(channel)
    Scanner.where(id: id, "scan_hook->>'ch'" => channel).update_all(scan_hook: nil)
  end

  class Handler
    def handle_http(subpath, &block)
    end

    def handle_mqtt(topic, &block)
    end
  end
end
