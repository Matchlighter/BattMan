class Battery < ApplicationRecord
  belongs_to :device

  has_paper_trail(
    only: %i[current_device]
  )
end
