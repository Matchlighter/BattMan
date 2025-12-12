class ScanLog < ApplicationRecord
  belongs_to :object, polymorphic: true, optional: true
  belongs_to :scanner

  def self.process_scan!(scanner, payload)
    log_entry = create!(scanner: scanner)
    PaperTrail.request.whodunnit = log_entry

    transaction do
      # TODO Process payload and apply changes
      #   Load scanned object
      #   Load Scanner context
      #   Validate timeout
      #   Find the nearest context item that object can belong to
      #   Update context to include the scanned object
    end

    changes = log_entry.changes
    # TODO Broadcast changed items
    # TODO Broadcast ScanLog to those watching the Scanner
  rescue StandardError => err
    log_entry.update!(
      status: "error",
      message: err.message,
    )

    raise err
  end

  def changes
    PaperTrail::Version.where(whodunnit: to_gid)
  end
end
