class ClientChannel < ApplicationCable::Channel
  def subscribed
    @uid = params[:uid] || SecureRandom.hex(8)
    @has_scan_hook = false

    stream_for @uid, coder: ActiveSupport::JSON do |message|
      # case message["type"]
      # else
      #   transmit(message)
      # end
      transmit(message)
    end

    transmit({ type: "assign_uid", uid: @uid })

    # TODO Dev
    # transmit({ type: "scanner_subscribed", scanner_id: "ABCD1234WXYZ" })
  end

  # def subscribe_scanner(scanner)
  #   scanner = Scanner.find(scanner) unless scanner.is_a?(Scanner)

  #   if @scanner
  #     stop_stream_from ScannerChannel.broadcasting_for(@scanner)
  #     release_scan_hook
  #   end

  #   @scanner = scanner
  #   stream_from ScannerChannel.broadcasting_for(@scanner)
  #   take_scan_hook if @has_scan_hook

  #   transmit({ type: "scanner_subscribed", scanner_id: @scanner.id })
  # end

  def take_scan_hook(pl)
    release_scan_hook if @hooked_scanner
    @hooked_scanner = Scanner.find(pl["scanner_id"]).tap do |scanner|
      scanner.set_scan_hook(@uid)
    end
  end

  def release_scan_hook
    @hooked_scanner&.release_scan_hook(@uid)
    @hooked_scanner = nil
  end

  def unsubscribed
    release_scan_hook
  end
end
