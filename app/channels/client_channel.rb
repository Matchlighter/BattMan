class ClientChannel < ApplicationCable::Channel
  def subscribed
    @uid = params[:uid]
    @has_scan_hook = false

    stream_for @uid, coder: ActiveSupport::JSON do |message|
      case message["type"]
      when "watch_scanner"
        subscribe_scanner(message["scanner_id"])
      else
        transmit(message)
      end
    end
  end

  def subscribe_scanner(scanner)
    scanner = Scanner.find(scanner) unless scanner.is_a?(Scanner)

    if @scanner
      stop_stream_from ScannerChannel.broadcasting_for(@scanner)
      release_scan_hook
    end

    @scanner = scanner
    stream_from ScannerChannel.broadcasting_for(@scanner)
    take_scan_hook if @has_scan_hook
  end

  def take_scan_hook
    @has_scan_hook = true
    @scanner.set_scan_hook(@uid)
  end

  def release_scan_hook
    @has_scan_hook = false
    @scanner.release_scan_hook(@uid)
  end

  def unsubscribed
    release_scan_hook
  end
end
