# frozen_string_literal: true

#
# Call this method in a before(:all) block at the top of your +describe+
def create_users
  # TODO: Phase these out with "let" assignments, and use traits to assign roles
  @admin = FactoryBot.create(:user, :administrator, username: "admin")
  @business_admin = FactoryBot.create(:user, username: "business_admin")
  @director = FactoryBot.create(:user, username: "director")
  @facility_admin = FactoryBot.create(:user, username: "facility_admin")
  @guest = FactoryBot.create(:user, username: "guest")
  @owner = FactoryBot.create(:user, username: "owner")
  @purchaser = FactoryBot.create(:user, username: "purchaser")
  @staff = FactoryBot.create(:user, username: "staff")
  @senior_staff = FactoryBot.create(:user, username: "senior_staff")
end

#
# This nifty method allows you to keep DRY the requests of a context.
# It relies on the following instance variables:
#
# * @method -- a +Symbol+ of a HTTP method (:get, :post, etc.)
# * @action -- the +Symbol+ of a controller action
# * @params -- a +Hash+ of requests parameters
#
# Once these instance variables are set you can call #do_request
# and the request described by the variables will be made.
# [_params_]
#   Overrides the @params variable
def do_request(params = nil)
  params ||= @params
  if @method == :xhr
    get @action, params: params, xhr: true
  else
    method(@method).call(@action, params: params.to_h)
  end
end

# This does what Users#switch_to does and sets the acting user.
# This will make ApplicationController#acting_as? return true and
# ApplicationController#acting_user return a user
def switch_to(user)
  session[:acting_user_id] = user.id
end

#
# The helpers below are useful for testing the authentication
# and authorization frameworks. They rely on the existence
# of let(:authable), which is the resource passed to +Ability#initialize+.
# They make requests for you using #do_request, so just set instance
# variables for it and you're good to go
#
# Note: instance variable @authable, also works for setup, but is deprecated
#

#
# Asserts that the request is redirected to the login page
def it_should_require_login
  it "should require login", auth: true do
    do_request
    is_expected.to redirect_to(new_user_session_url)
  end
end

#
# Asserts that the user is denied authorization
# [_user_sym_]
#   The +Symbol+ic username of the #create_users user to test
# [_spec_desc_]
#   If present is passed to the spec as its description
def it_should_deny(user_sym, spec_desc = "")
  it "should deny #{user_sym} " + spec_desc, auth: true do
    maybe_grant_always_sign_in(user_sym)
    do_request
    is_expected.to render_template("403")
  end
end

#
# Grants a user a role based on their username and signs them in
# allowance of authorization is tested in the given block
# [_user_sym_]
#   The +Symbol+ic username of the #create_users user to test
# [_spec_desc_]
#   If present is passed to the spec as its description
# [_eval_]
#   block of tests to be evaluated after roles are
#   granted and the user is signed in
def it_should_allow(user_sym, spec_desc = "", &eval)
  it "should allow #{user_sym} " + spec_desc, auth: true do
    maybe_grant_always_sign_in(user_sym)
    do_request
    instance_eval(&eval)
  end
end

#
# The *_all helpers are useful for testing multiple roles in one shot.
# They generate a new spec for each role and behave just like their
# single counterparts above
# [_user_syms_]
#   An Array of the +Symbol+ic usernames of #create_users users to test
#

def it_should_deny_all(user_syms, spec_desc = "")
  user_syms.each { |user_sym| it_should_deny user_sym, spec_desc }
end

def it_should_allow_all(user_syms, spec_desc = "", &eval)
  user_syms.each do |user_sym|
    it "should allow #{user_sym} " + spec_desc, auth: true do
      user = maybe_grant_always_sign_in(user_sym)
      do_request
      instance_exec(user, &eval)
    end
  end
end

#
# Convenient params for *_all helpers
#

def facility_managers
  [:admin, :director]
end

def facility_operators
  facility_managers + [:staff, :senior_staff]
end

def facility_users
  facility_operators + [:guest]
end

#
# Bundles the common test suite of ensuring an action requires
# login, denies facility staff, and allows facility managers.
# [_response_]
#   The expected HTTP status on a successful auth. Can be
#   anything expected by +Shoulda::Matchers::ActionController#respond_with+.
#   Defaults to :success
# [_spec_desc_]
#   If present is passed to the spec as its description
# [_eval_]
#   A block holding successful auth tests. If given will be passed the
#   user whose auth is currently being tested. Not required.
def it_should_allow_managers_only(response = :success, spec_desc = "", &eval)
  it_should_require_login

  it_should_deny(:guest, spec_desc)

  it_should_deny(:staff, spec_desc)

  it_should_deny(:senior_staff)

  it_should_allow_all(facility_managers, spec_desc) do |user|
    is_expected.to respond_with response
    instance_exec(user, &eval) if eval
  end
end

def it_should_allow_managers_and_senior_staff_only(response = :success, spec_desc = "", &eval)
  it_should_require_login

  it_should_deny(:guest, spec_desc)

  it_should_deny(:staff, spec_desc)

  it_should_allow_all(facility_managers + [:senior_staff], spec_desc) do |user|
    is_expected.to respond_with response
    instance_exec(user, &eval) if eval
  end
end

#
# Similar to #it_should_allow_managers_only, but for operators
def it_should_allow_operators_only(response = :success, spec_desc = "", &eval)
  it_should_require_login

  it_should_deny(:guest, spec_desc)

  it_should_allow_all(facility_operators, spec_desc) do |user|
    is_expected.to respond_with response
    instance_exec(user, &eval) if eval
  end
end

#
# Similar to #it_should_allow_managers_only, but tests admin access
def it_should_allow_admin_only(response = :success, spec_desc = "", &eval)
  it_should_require_login

  it_should_deny(:guest, spec_desc)

  it_should_deny(:director, spec_desc)

  it_should_deny(:staff, spec_desc)

  it_should_allow(:admin, spec_desc) do
    is_expected.to respond_with response
    instance_eval(&eval) if eval
  end
end

#
# Helpers for the above API. Stand-alone use is discouraged.
#

def grant_role(user, authable = nil)
  if authable.nil?
    authable = @authable
    authable = send(:authable) if authable.nil? && respond_to?(:authable)
  end

  case user.username
  when "facility_admin"
    UserRole.grant(user, UserRole::FACILITY_ADMINISTRATOR, authable)
    expect(user.reload).to be_facility_administrator_of(authable)
  when "director"
    UserRole.grant(user, UserRole::FACILITY_DIRECTOR, authable)
    expect(user.reload).to be_facility_director_of(authable)
  when "staff"
    UserRole.create!(user: user, role: UserRole::FACILITY_STAFF, facility: authable) unless user.facility_staff_of?(authable)
    expect(user.reload).to be_facility_staff_of(authable)
  when "owner"
    # Creating a NufsAccount requires an owner to be present, and some pre-Rails3 tests try to add the same user
    # to the same account with the same role of owner. That's a uniqueness error on AccountUser. Avoid it.
    existing = AccountUser.find_by(user_id: user.id, account_id: authable.id, user_role: AccountUser::ACCOUNT_OWNER)
    AccountUser.grant(user, AccountUser::ACCOUNT_OWNER, authable, by: @admin) unless existing
    expect(user.reload).to be_owner_of(authable)
  when "purchaser"
    AccountUser.grant(user, AccountUser::ACCOUNT_PURCHASER, authable, by: @admin)
    expect(user.reload).to be_purchaser_of(authable)
  when "business_admin"
    AccountUser.grant(user, AccountUser::ACCOUNT_ADMINISTRATOR, authable, by: @admin)
    expect(user.reload).to be_business_administrator_of(authable)
  when "senior_staff"
    UserRole.grant(user, UserRole::FACILITY_SENIOR_STAFF, authable)
    expect(user.reload).to be_facility_senior_staff_of(authable)
  end
end

def grant_and_sign_in(user)
  grant_role(user) unless user == @guest || user == @admin
  sign_in user
  user
end

def maybe_grant_always_sign_in(user_sym)
  user = instance_variable_get("@#{user_sym}")
  grant_and_sign_in(user)
end
