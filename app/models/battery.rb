class Battery < ApplicationRecord
  belongs_to :current_device, class_name: "Device", optional: true

  PATTERN = /^(LI|NiMH|LFP)-/

  BRAND_MAP = {
    "PB" => "PaleBlue",
    "AT" => "AmpTorrent",
    "Tn" => "Tenergy",
  }

  has_paper_trail(
    only: %i[current_device_id]
  )

  def brand_name
    BRAND_MAP[parsed_id[:brand]] || "Unknown"
  end

  def chemistry
    parsed_id[:chemistry]
  end

  def size
    parsed_id[:size]
  end

  def parsed_id
    bits = id.split("-")
    {
      chemistry: bits[0],
      size: bits[1],
      brand: bits[2],
      instance: bits[3]
    }
  end
end
