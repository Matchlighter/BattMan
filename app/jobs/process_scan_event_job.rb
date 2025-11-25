class ProcessScanEventJob < ApplicationJob
  queue_as :default

  class ScanError < StandardError; end

  attr_reader :scanner
  attr_reader :scan_log

  def perform(raw_message)
    message = JSON.parse(raw_message)
    puts "Processing scan event: #{message.inspect}"

    scanner_id = message["id"]
    payload = message["msg"]
    puts "Scanner ID: #{scanner_id}, Payload: #{payload}"

    @scanner = Scanner.find_or_initialize_by(id: scanner_id)
    @scan_log = ScanLog.new(scanner: scanner, payload: payload)

    PaperTrail.request.whodunnit = "scanner:#{scanner.id}"

    case payload
    when Device::PATTERN
      process_device_scan(payload)
    when Battery::PATTERN
      process_battery_scan(payload)
    else
      raise ScanError, "Unknown payload format"
    end

    scanner.updated_at = Time.current
    scanner.save

    sleep(0.2)
    scanner.beep!(1)
  rescue ScanError => e
    scan_log.status = "error"
    scan_log.message = e.message

    puts "ScanError: #{e.message}"
    # TODO Broadcast to UI
    sleep(0.2)
    scanner.beep!(2)
  rescue StandardError => e
    if scan_log.present?
      scan_log.status = "error"
      scan_log.message = "Internal error processing scan: #{e.message}"
    end

    sleep(0.2)
    scanner.beep!(3) if scanner
    raise e
  ensure
    scan_log&.save!
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
