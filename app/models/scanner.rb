class Scanner < ApplicationRecord
  class ScanError < StandardError; end

  BATTMAN_REGEX = /^(?<url>.*\/scan\/)BATTMAN:(?<code>.*)$/

  def self.process_scan_event!(scanner_id, payload)
    scanner = Scanner.find_or_create_by(id: scanner_id)

    if (m = BATTMAN_REGEX.match(payload))
      meta = m["code"]

      # Tell the client Channel to subscribe to the scanner
      if (m = /^CLIENT:(\w+):(.*)$/.match(meta))
        client_uid = m[1]
        ClientChannel.broadcast_to(client_uid, {
          type: "client_scanned",
          scanner_id: scanner.id,
          payload: m[2],
        })
      end
    elsif scanner && (client_uid = scanner.scan_hook).present?
      ClientChannel.broadcast_to(client_uid, {
        type: "scan",
        scanner_id: scanner.id,
        hooked: true,
        payload: payload,
      })
    else
      ScanLog.process_scan!(scanner, payload)
    end
  rescue StandardError => err
    puts("Error processing scan event for scanner #{scanner_id}: #{err.message}", err.backtrace)
    raise err
  end

  def scan_hook
    h = attributes["scan_hook"]
    return unless h && h["exp"] > Time.now.to_i
    h["ch"]
  end

  def set_scan_hook(channel)
    update(scan_hook: { "ch" => channel, "exp" => (Time.now + 10.minutes).to_i })
  end

  def release_scan_hook(channel)
    Scanner.where2(id: id, scan_hook: { ch: channel }).update_all(scan_hook: nil)
  end
end
