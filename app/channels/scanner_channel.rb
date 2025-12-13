class ScannerChannel < ApplicationCable::Channel
  def subscribed
    @scanner = Scanner.find(params[:scanner_id])
    stream_for @scanner
  end

  def unsubscribed
  end
end
