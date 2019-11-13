# frozen_string_literal: true

class UserForm < SimpleDelegator

  include ActiveModel::Validations

  def model_name
    ActiveModel::Name.new(user.class)
  end

  def to_model
    self
  end

  def self.permitted_params
    [:email, :first_name, :last_name, :username]
  end

  def user
    __getobj__
  end

  def valid?
    success = [super, user.valid?].all?

    user.errors.each do |k, error_messages|
      errors.add(k, error_messages)
    end

    success
  end

  def save
    set_password if user.new_record?

    valid? && user.save
  end

  def update_attributes(params)
    user.assign_attributes(params)
    save
  end

  def admin_editable?
    user.email_user?
  end

  def username_editable?
    false
  end

  private

  def set_password
    user.password = generate_new_password
  end

  def generate_new_password
    chars = ("a".."z").to_a + ("1".."9").to_a + ("A".."Z").to_a
    chars.sample(8).join
  end

end
