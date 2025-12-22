class ClientChannel < ApplicationCable::Channel
  periodically :touch_connected_state, every: 90.seconds

  def subscribed
    @uid = params[:uid] || SecureRandom.hex(8)
    @has_scan_hook = false

    stream_for @uid, coder: ActiveSupport::JSON do |message|
      transmit(message)
    end

    transmit({ type: "assign_uid", uid: @uid })

    touch_connected_state
  end

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
    Rails.cache.delete("client:#{@uid}:connected")
  end

  protected

  def touch_connected_state
    Rails.cache.write("client:#{@uid}:connected", true, expires_in: 2.minutes)
  end
end
