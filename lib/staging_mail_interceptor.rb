# MailInterceptor intercepts email delivery, preventing messages from being sent
# to non-developers, and re-routing messages intended for other recipients to
# the development team. This allows us to play around in the staging and testing
# environments without fear of emails going to production customers.
#
# http://thepugautomatic.com/2012/08/abort-mail-delivery-with-rails-3-interceptors/
class StagingMailInterceptor

  attr_accessor :message

  # Public: A hook invoked by Rails when delivering an email. Initializes and
  # processes a new interceptor.
  #
  # Returns nothing.
  def self.delivering_email(message)
    new(message).process
  end

  # Public: Initialize a new StagingMailInterceptor for the passed message.
  #
  # message - A Mail::Message.
  def initialize(message)
    @message = message
  end

  # Public: Process the StagingMailInterceptor, modifying the message object
  # to avoid sending email to actual customers in non-production environments.
  #
  # Returns nothing.
  def process
    message.subject = subject

    return if all_addresses_whitelisted?

    message.body = body

    message.to = whitelisted_addresses
    message.cc = nil
    message.bcc = nil
  end

  private

  # Internal: Get the message's subject line, prefixed for this environment.
  #
  # Returns a String.
  def subject
    "[#{I18n.t('app_name')} #{Rails.env.upcase}] #{message.subject}"
  end

  # Internal: Get the content of this email, modified with a list of the email
  # addresses to which the email was originally supposed to be delivered.
  #
  # Returns a String.
  def body
    intercepted_message = "<pre>Intercepted email:\n  to: #{message.to}\n  cc: #{message.cc}\n  bcc: #{message.bcc}</pre>"
    "#{intercepted_message}\n\n#{message.body}"
  end

  # Internal: Is the passed recipient whitelisted for communication? Permits
  # communication only with either Table XI employees or emails listed in
  # secrets in the staging environment.
  #
  # Returns a Boolean.
  def whitelisted?(recipient)
    recipient = Mail::Address.new(recipient)
    recipient.domain == "tablexi.com" ||
      send_to_addresses.include?(recipient.address) ||
      whitelist.include?(recipient.address) ||
      exception_recipients.include?(recipient.address)
  end

  # Internal: Get a list of the whitelisted email addresses for this message.
  # If no email addresses are whitelisted, defaults to the configured exception
  # notification email address.
  #
  # Returns a String or Array of Strings.
  def whitelisted_addresses
    message.to.select { |recipient| whitelisted?(recipient) }.presence ||
      send_to_addresses
  end

  # Internal: Are all target email addresses whitelisted?
  #
  # Returns a Boolean.
  def all_addresses_whitelisted?
    message.to.all? { |recipient| whitelisted?(recipient) } &&
      message.cc.blank? &&
      message.bcc.blank?
  end

  def send_to_addresses
    Array(settings[:to])
  end

  def whitelist
    Array(settings[:whitelist])
  end

  def exception_recipients
    Array(Settings[:exceptions].try(:[], :recipients))
  end

  def settings
    Settings.email.fake || raise("Settings.email.fake is not configured!")
  end

end
