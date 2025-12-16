class ScanLog < ApplicationRecord
  belongs_to :scanner

  ScanError = Scanner::ScanError

  def self.process_scan!(scanner, payload)
    log_entry = create!(scanner: scanner, payload: payload, status: "ok")
    PaperTrail.request.whodunnit = log_entry
    log_entry.process_scan!(payload)
  end

  def process_scan!(payload)
    if payload.match?(/^https?:\/\//)
      raise ScanError, "URL Scanned"
    else
      process_linking_scan!(payload)
    end

  rescue StandardError => err
    update!(
      status: "error",
      message: err.message,
    )

    raise err
  ensure
    # Broadcast ScanLog to those watching the Scanner
    ScannerChannel.broadcast_to(scanner, {
      type: "scan",
      scan_log_id: self.id,
      status: status,
      message: message,
      payload: payload,
      # changes: changes,
    })
  end

  def changes
    PaperTrail::Version.where(whodunnit: to_gid.to_s)
  end

  protected

  def process_linking_scan!(payload)
    transaction do
      # TODO Process payload and apply changes
      #   Load scanned object
      #   Load Scanner context
      #   Validate timeout
      #   Find the nearest context item that object can belong to
      #   Update context to include the scanned object
    end

    # Broadcast changed items
    changes.each do |change|
      ThingChannel.broadcast_to(change.item, ApplicationController.render(
        template: 'api/v1/things/show',
        assigns: { thing: change.item },
      ))
    end
  end
end
