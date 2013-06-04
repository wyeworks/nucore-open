require 'rubygems'
require 'spork'

# --- Instructions ---
# - Sort through your spec_helper file. Place as much environment loading
#   code that you don't normally modify during development in the
#   Spork.prefork block.
# - Place the rest under Spork.each_run block
# - Any code that is left outside of the blocks will be ran during preforking
#   and during each_run!

# View helpers are not being loaded in when running spork. Once the pull request is
# merged in and spork is upgraded, we should be able to remove this line.
# https://github.com/sporkrb/spork/pull/140
if Spork.using_spork?
  AbstractController::Helpers::ClassMethods.module_eval do def helper(*args, &block); modules_for_helpers(args).each {|mod| add_template_helper(mod)}; _helpers.module_eval(&block) if block_given?; end end
end

Spork.prefork do
  # This file is copied to ~/spec when you run 'ruby script/generate rspec'
  # from the project root directory.
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)

  require 'rspec/rails'
  require 'factory_girl'
  require 'shoulda-matchers'

  #
  # Check for engine factories. If they exist and the engine is in use load it up
  Dir[File.expand_path('vendor/engines/*', Rails.root)].each do |engine|
    engine_name=File.basename engine
    factory_file=File.join(engine, 'spec/factories.rb')
    require factory_file if File.exist?(factory_file) && EngineManager.engine_loaded?(engine_name)
  end

  # Uncomment the next line to use webrat's matchers
  #require 'webrat/integrations/rspec-rails'

  # Requires supporting files with custom matchers and macros, etc,
  # in ./support/ and its subdirectories.
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

  RSpec.configure do |config|
    # If you're not using ActiveRecord you should remove these
    # lines, delete config/database.yml and disable :active_record
    # in your config/boot.rb
    config.use_transactional_fixtures = true

    # == Fixtures
    #
    # You can declare fixtures for each example_group like this:
    #   describe "...." do
    #     fixtures :table_a, :table_b
    #
    # Alternatively, if you prefer to declare them only once, you can
    # do so right here. Just uncomment the next line and replace the fixture
    # names with your fixtures.
    #
    # config.global_fixtures = :table_a, :table_b
    #
    # If you declare global fixtures, be aware that they will be declared
    # for all of your examples, even those that don't use them.
    #
    # You can also declare which fixtures to use (for example fixtures for test/fixtures):
    #
    # config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
    #
    # == Mock Framework
    #
    # RSpec uses its own mocking framework by default. If you prefer to
    # use mocha, flexmock or RR, uncomment the appropriate line:
    #
    # config.mock_with :mocha
    # config.mock_with :flexmock
    # config.mock_with :rr
    #
    # == Notes
    #
    # For more information take a look at Spec::Runner::Configuration and Spec::Runner

    config.include Devise::TestHelpers, :type => :controller

    config.before(:all) do
      # users are not created within transactions, so delete them all here before running tests
      UserRole.delete_all
      User.delete_all

      # initialize order status constants
      @os_new        = OrderStatus.find_or_create_by_name('New')
      @os_in_process = OrderStatus.find_or_create_by_name('In Process')
      @os_complete   = OrderStatus.find_or_create_by_name('Complete')
      @os_cancelled  = OrderStatus.find_or_create_by_name('Cancelled')
      @os_reconciled  = OrderStatus.find_or_create_by_name('Reconciled')

      # initialize affiliates
      Affiliate.find_or_create_by_name('Other')

      # initialize price groups
      @nupg = PriceGroup.find_or_create_by_name(:name => Settings.price_group.name.base, :is_internal => true, :display_order => 1)
      @nupg.save(:validate => false)
      @ccpg = PriceGroup.find_or_create_by_name(:name => Settings.price_group.name.cancer_center, :is_internal => true, :display_order => 2)
      @ccpg.save(:validate => false)
      @epg = PriceGroup.find_or_create_by_name(:name => Settings.price_group.name.external, :is_internal => false, :display_order => 3)
      @epg.save(:validate => false)

      #now=Time.zone.parse("#{Date.today.to_s} 09:30:00")
      Timecop.return
      now=(SettingsHelper::fiscal_year_beginning(Date.today) + 1.year + 10.days).change(:hour => 9, :min => 30)
      #puts "travelling to #{now}"
      Timecop.travel(now)
    end
  end
end


Spork.each_run do
  # used by factory to find or create order status
  def find_order_status(status)
    OrderStatus.find_or_create_by_name(status)
  end

  def assert_true(x)
    assert(x)
  end

  def assert_false(x)
    assert(!x)
  end

  def assert_not_valid(x)
    assert !x.valid?
  end

  def assert_nil(x)
    assert_equal nil, x
  end

  #
  # Asserts that the model +var+
  # no longer exists in the DB
  def should_be_destroyed(var)
    dead=false

    begin
      var.class.find var.id
    rescue
      dead=true
    end

    assert dead
  end


  #
  # Factory wrapper for creating an account with owner
  def create_nufs_account_with_owner(owner=:owner)
    owner=instance_variable_get("@#{owner.to_s}")
    FactoryGirl.create(:nufs_account, :account_users_attributes => [ FactoryGirl.attributes_for(:account_user, :user => owner) ])
  end

  # Simulates placing an order for a product
  # [_ordered_by_]
  #   The user who is ordering the product
  # [_facility_]
  #   The facility with which the order is placed
  # [_product_]
  #   The product being ordered
  # [_account_]
  #   The account under which the order is placed
  def place_product_order(ordered_by, facility, product, account=nil, purchased=true)
    @price_group=FactoryGirl.create(:price_group, :facility => facility)

    o_attrs={ :created_by => ordered_by.id, :facility => facility, :ordered_at => Time.zone.now }
    o_attrs.merge!(:account_id => account.id) if account
    o_attrs.merge!(:state => 'purchased') if purchased
    @order=ordered_by.orders.create(FactoryGirl.attributes_for(:order, o_attrs))

    FactoryGirl.create(:user_price_group_member, :user => ordered_by, :price_group => @price_group)
    @item_pp=product.send(:"#{product.class.name.downcase}_price_policies").create(FactoryGirl.attributes_for(:"#{product.class.name.downcase}_price_policy", :price_group_id => @price_group.id))
    @item_pp.reload.restrict_purchase=false
    od_attrs={ :product_id => product.id }
    od_attrs.merge!(:account_id => account.id) if account
    @order_detail = @order.order_details.create(FactoryGirl.attributes_for(:order_detail).update(od_attrs))

    @order_detail.set_default_status! if purchased

    @order_detail
  end

  #
  # Simulates placing an order for an item and having it marked complete
  # [_ordered_by_]
  #   The user who is ordering the item
  # [_facility_]
  #   The facility with which the order is placed
  # [_account_]
  #   The account under which the order is placed
  # [_reviewed_]
  #   true if the completed order should also be marked as reviewed, false by default
  def place_and_complete_item_order(ordered_by, facility, account=nil, reviewed=false)
    @facility_account=facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @item=facility.items.create(FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account.id))
    place_product_order(ordered_by, facility, @item, account)

    # act like the parent order is valid
    @order.state = 'validated'

    # purchase it
    @order.purchase!

    @order_detail.change_status!(OrderStatus.complete.first)

    od_attrs={
      :actual_cost => 20,
      :actual_subsidy => 10,
      :price_policy_id => @item_pp.id
    }

    od_attrs.merge!(:reviewed_at => Time.zone.now-1.day) if reviewed
    @order_detail.update_attributes(od_attrs)
    return @order_detail
  end

  #
  # Simulates creating a reservation to a pre-defined instrument
  # [_ordered_by_]
  #   The user who is ordering the items
  # [_instrument_]
  #   The instrument the reservation is being placed on
  # [_account_]
  #   The account under which the order is placed
  # [_reserved_start_]
  #   The datetime that the reservation is to begin
  # [_extra_reservation_attrs_]
  #   Other parameters for the reservation; will override the defaults defined below
  #
  # and_return the reservation
  def place_reservation_for_instrument(ordered_by, instrument, account, reserve_start, extra_reservation_attrs=nil)
    order_detail = place_product_order(ordered_by, instrument.facility, instrument, account, false)

    instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule)) if instrument.schedule_rules.empty?
    res_attrs={
      :reserve_start_at => reserve_start,
      :order_detail => order_detail,
      :duration_value => 60,
      :duration_unit => 'minutes'
    }

    res_attrs.merge!(extra_reservation_attrs) if extra_reservation_attrs
    instrument.reservations.create(res_attrs)
  end

  #
  # Creates a +Reservation+ for a newly created +Instrument+ that is party
  # of +facility+. The reservation is made for +order_detail+ and starts
  # at +reserve_start+. Variables +@instrument+ and +@reservation+ are
  # available for use once the method completes.
  # [_facility_]
  #   The +Facility+ for which the new +Instrument+ will be created
  # [_order_detail_]
  #   The +OrderDetail+ that the +Reservation+ will belong to
  # [_reserve_start_]
  #   An +ActiveSupport::TimeWithZone+ object representing the time the
  #   +Reservation+ should begin
  # [_extra_reservation_attrs_]
  #   Custom attributes for the +Reservation+, if any
  def place_reservation(facility, order_detail, reserve_start, extra_reservation_attrs=nil)
    # create instrument, min reserve time is 60 minutes, max is 60 minutes
    @instrument ||= FactoryGirl.create(
          :instrument,
          :facility => facility,
          :facility_account => facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account)),
          :min_reserve_mins => 60,
          :max_reserve_mins => 60)


    assert @instrument.valid?
    @instrument.schedule_rules.create!(FactoryGirl.attributes_for(:schedule_rule, :start_hour => 0, :end_hour => 24)) if @instrument.schedule_rules.empty?

    res_attrs={
      :reserve_start_at => reserve_start,
      :order_detail => order_detail,
      :duration_value => 60,
      :duration_unit => 'minutes'
    }
    order_detail.update_attributes!(:product => @instrument)
    order_detail.order.update_attributes!(:state => 'purchased')

    res_attrs.merge!(extra_reservation_attrs) if extra_reservation_attrs
    @reservation=@instrument.reservations.build(res_attrs)
    # force validation to run to set reserve_end_at, but ignore the errors
    # we don't need to be worried about all the validations when running this method
    @reservation.valid?
    @reservation.save(:validate => false)
    @reservation
  end


  #
  # Sets up an environment for testing reservations by creating records for
  # and assigning the following instance variables:
  # - @instrument
  # - @price_group
  # - @order
  # - @order_detail
  # Gives you everything you need to #place_reservation.
  # [_facility_]
  #   The facility that all assigned variables relate to
  # [_facility_account_]
  #   The account that @instrument is associated with
  # [_account_]
  #   The account used to place @order
  # [_user_]
  #   The +User+ that creates the @order
  def setup_reservation(facility, facility_account, account, user)
    # create instrument, min reserve time is 60 minutes, max is 60 minutes
    @instrument       = FactoryGirl.create(:instrument,
                                             :facility => facility,
                                             :facility_account => facility_account,
                                             :min_reserve_mins => 60,
                                             :max_reserve_mins => 60)
    assert @instrument.valid?
    @price_group      = facility.price_groups.create(FactoryGirl.attributes_for(:price_group))
    FactoryGirl.create(:price_group_product, :product => @instrument, :price_group => @price_group)
    # add rule, available every day from 9 to 5, 60 minutes duration
    @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule, :end_hour => 23))
    # create price policy with default window of 1 day
    @instrument.instrument_price_policies.create(FactoryGirl.attributes_for(:instrument_price_policy).update(:price_group_id => @price_group.id))
    # create order, order detail
    @order            = user.orders.create(FactoryGirl.attributes_for(:order, :created_by => user.id, :account => account, :ordered_at => Time.zone.now))
    @order.add(@instrument, 1)
    @order_detail     = @order.order_details.first
  end

  #
  # Sets up an instrument and all the necessary environment to be ready for
  # placing reservations. Assigns the following variables:
  # - @instrument
  # - @authable (aka facility)
  # - @facility_account
  # - @price_group
  # - @rule (schedule rule)
  # - @price_group_product
  #
  def setup_instrument(instrument_options = {})
    @instrument = FactoryGirl.create(:setup_instrument, instrument_options)
    @facility = @authable = @instrument.facility
    @facility_account = @instrument.facility.facility_accounts.first
    @price_group = @instrument.price_groups.last
    @price_policy = @instrument.price_policies.last
    @rule = @instrument.schedule_rules.first
    @price_group_product = @instrument.price_group_products.first
    @instrument
  end

  def account_users_attributes_hash(options = {})
    options[:user] ||= @user
    options[:created_by] ||= options[:user].id
    # force created_by to a fixnum id
    options[:created_by] = options[:created_by].kind_of?(Fixnum) ? options[:created_by] : options[:created_by].id

    options[:user_role] ||= AccountUser::ACCOUNT_OWNER
    [Hash[options]]
  end

  #
  # Sets up a user with an account and as part of a price group
  # Sets the following instance variables
  # - @account
  # - @pg_member
  def setup_user_for_purchase(user, price_group)
    @account          = FactoryGirl.create(:nufs_account, :account_users_attributes => account_users_attributes_hash(:user => user))
    @pg_member        = FactoryGirl.create(:user_price_group_member, :user => user, :price_group => price_group)
  end


  # If you changed Settings anywhere in your spec, include this as
  # in after :all to reset to the normal settings.
  def reset_settings
    Settings.reload_from_files(
      Rails.root.join("config", "settings.yml").to_s,
      Rails.root.join("config", "settings", "#{Rails.env}.yml").to_s,
      Rails.root.join("config", "environments", "#{Rails.env}.yml").to_s
    )
  end
end
