class ProcessScanEventJob < ApplicationJob
  queue_as :default

  attr_reader :scanner
  attr_reader :scan_log

  def perform(raw_message)
    message = JSON.parse(raw_message)
    puts "Processing scan event: #{message.inspect}"

    scanner_id = message["id"]
    payload = message["msg"]
    puts "Scanner ID: #{scanner_id}, Payload: #{payload}"

    Scanner.process_scan_event!(scanner_id, payload)
  end

  protected

  def process_device_scan(device_id)
    device_id = device_id[4..-1] if device_id.start_with?("DEV-")

    device = Device.find_or_initialize_by(id: device_id)
    scan_log.object = device
    scanner.state["current_device_id"] = device.id
    device.save
  end

  def process_battery_scan(battery_id)
    battery = Battery.find_or_initialize_by(id: battery_id)
    scan_log.object = battery

    raise ScanError, "Scanner inactive for too long" if scanner.updated_at < 5.minutes.ago

    device = Device.find_by(id: scanner.state["current_device_id"])
    raise ScanError, "No device selected on scanner" unless device

    battery.current_device = device

    battery.save
  end
end
