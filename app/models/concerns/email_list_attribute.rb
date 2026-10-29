# frozen_string_literal: true

# Include this module in a model to add that attribute that acts like an array
# but is backed by a comma-separated string in the database.
#
# class Product < ApplicationRecord
#   include EmailListAttribute
#   email_list_attribute :contact_emails
# end
#
# > product = Product.new
# > product.contact_emails = "email1@example.com, email2@example.com"
# > product.contact_emails.map { |email| email }
#   => ["email1@example.com", "email2@example.com"]
module EmailListAttribute
  extend ActiveSupport::Concern

  module ClassMethods
    def email_list_attribute(attribute_name)
      define_method(attribute_name) do
        CsvArrayString.new(self[attribute_name])
      end

      define_method("#{attribute_name}=") do |string|
        self[attribute_name] = CsvArrayString.new(string)
      end

      validate do |record|
        # A simple validation that just makes sure there's an @ symbol in between
        # some characters.
        record.errors.add(attribute_name, :invalid) unless public_send(attribute_name).all? { |email| email =~ /.@\w/ }
      end
    end
  end
end
