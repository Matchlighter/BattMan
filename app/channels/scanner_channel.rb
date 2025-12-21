class ScannerChannel < ApplicationCable::Channel
  def subscribed
    @scanner = Scanner.find(params[:scanner_id])
    stream_for @scanner
  end

  def emulate_scan(pl)
    ScanLog.process_scan!(@scanner, pl["payload"])
  end

  def unsubscribed
  end
end
