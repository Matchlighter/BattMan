class MobileScannerChannel < ApplicationCable::Channel
  def subscribed
    introducer_id = params[:introducer_id]

    # Require that the introducer client is connected - this will serve as "auth" for now
    unless Rails.cache.read("client:#{introducer_id}:connected")
      reject
      return
    end

    @scanner = Scanner.find_or_create_by(id: params[:scanner_id])
  end

  def scan(pl)
    Scanner.process_scan_event!(@scanner.id, pl["payload"])
  end

  def unsubscribed
    if @scanner
      ClientChannel.broadcast_to(params[:introducer_id], {
        type: "scanner_disconnected",
        scanner_id: @scanner.id,
      })
    end
  end
end
