# frozen_string_literal: true

module BulkEmail

  class DeliveryForm

    include ActiveModel::Model

    attr_accessor :custom_subject, :custom_message, :recipient_ids, :product_id, :search_criteria
    attr_reader :facility, :user, :content_generator

    validates :recipient_ids, presence: true
    validates :custom_subject, :custom_message, presence: true, unless: :product_offline?

    def initialize(user, facility, content_generator)
      @user = user
      @facility = facility
      @content_generator = content_generator
    end

    def assign_attributes(params)
      params ||= {}
      @custom_message = params[:custom_message]
      @custom_subject = params[:custom_subject]
      @recipient_ids = params[:recipient_ids]
      @product_id = params[:product_id]
      @search_criteria = parse_json_hash(params[:search_criteria])
    end

    def deliver_all
      if valid?
        BulkEmail::Job.transaction do
          recipients.each { |recipient| deliver(recipient) }
          record_delivery
        end
      end
    end

    private

    def product_offline?
      product&.offline?
    end

    def subject
      "#{content_generator.subject_prefix} #{custom_subject}"
    end

    def body
      content_generator.wrap_text(custom_message)
    end

    def reply_to
      product.try(:contact_email).presence || facility.email
    end

    def deliver(recipient)
      Mailer
        .send_mail(recipient: recipient, subject: subject, body: body, reply_to: reply_to, facility: SerializableFacility.new(facility))
        .deliver_later
    end

    def recipients
      @recipients ||= User.where_ids_in(recipient_ids)
    end

    def record_delivery
      BulkEmail::Job.create!(
        facility: facility,
        user: user,
        subject: subject,
        body: body,
        recipients: recipients.map(&:email),
        search_criteria: search_criteria,
      )
    end

    def product
      Product.find(product_id) if product_id.present?
    end

    def parse_json_hash(string)
      hash = JSON.parse(string.presence || "{}")
      hash.is_a?(Hash) ? hash : {}
    rescue JSON::ParserError, TypeError
      {}
    end

  end

end
