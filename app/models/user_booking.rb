class UserBooking < ActiveRecord::Base
  belongs_to :booking
  belongs_to :user
  belongs_to :bagage
	validates :booking_id,   presence: true
	validates :bagage_id,   presence: true
	validates :user_id, presence: true
end
