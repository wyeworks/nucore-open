module UmassCorum
  module UserExtension
	extend ActiveSupport::Concern

	included do
	  validates :umass_emplid, uniqueness: { allow_blank: true, case_sensitive: false }
	end
  end
end