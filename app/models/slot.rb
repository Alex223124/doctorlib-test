class Slot < ApplicationRecord

  belongs_to :opening, :class_name => "Event", required: true

end