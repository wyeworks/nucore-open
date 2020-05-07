# frozen_string_literal: true

# This file contains a base set of data appropriate for development or testing.
# The data can then be loaded with the rake db:bi_seed.
#
# !!!! BE AWARE that ActiveRecord's #find_or_create_by... methods do not
# always work properly! You're better off doing a #find_by, checking
# the return's existence, and creating if necessary !!!!
namespace :demo do
  desc "bootstrap db with data appropriate for demonstration"

  task seed: :environment do
    new_status = OrderStatus.find_or_create_by!(name: "New")
    in_process = OrderStatus.find_or_create_by!(name: "In Process")
    canceled   = OrderStatus.find_or_create_by!(name: "Canceled")
    complete   = OrderStatus.find_or_create_by!(name: "Complete")
    reconciled = OrderStatus.find_or_create_by!(name: "Reconciled")

    facility = Facility.find_or_create_by!(url_name: "example") do |example_facility|
      example_facility.name = "Example Facility"
      example_facility.abbreviation = "EF"
      example_facility.short_description = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam in mi tellus. Nunc ut turpis rhoncus mauris vehicula volutpat in fermentum metus. Sed eleifend purus at nunc facilisis fermentum metus."
      example_facility.description = "<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris scelerisque metus et augue elementum ac pellentesque neque blandit. Nunc ultrices auctor velit, et ullamcorper lacus ultrices id. Pellentesque vulputate dapibus mauris, sollicitudin mollis diam malesuada nec. Fusce turpis augue, consectetur nec consequat nec, tristique sit amet urna. Nunc vitae imperdiet est. Aenean gravida, risus eget posuere fermentum, risus odio bibendum ligula, sit amet lobortis enim odio facilisis ipsum. Donec iaculis dolor vitae massa ullamcorper pulvinar. In hac habitasse platea dictumst. Pellentesque iaculis sapien id est auctor a semper odio tincidunt. Suspendisse nec lectus sit amet est imperdiet elementum non sagittis nulla. Sed tempor velit nec sapien rhoncus consequat semper neque malesuada. Nunc gravida justo in felis tempus dapibus. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Duis tristique diam dolor. Curabitur lacinia molestie est vel mollis. Ut facilisis vestibulum scelerisque. Aenean placerat purus in nisi auctor scelerisque.</p>"
      example_facility.address = "Example Facility\nFinancial Dept\n111 University Rd.\nEvanston, IL 60201-0111"
      example_facility.phone_number = "(312) 123-4321"
      example_facility.fax_number = "(312) 123-1234"
      example_facility.email = "example-support@example.com"
      example_facility.is_active = true
    end

    # create chart strings, which are required when creating a facility account and nufs account
    chart_strings = [
      {
        budget_period: "-", fund: "123", department: "1234567", project: "12345678",
        activity: "01", account: "50617", starts_at: Time.zone.now - 1.week, expires_at: Time.zone.now + 1.year
      },

      {
        budget_period: "-", fund: "111", department: "2222222", project: "33333333",
        activity: "01", account: "50617", starts_at: Time.zone.now - 1.week, expires_at: Time.zone.now + 1.year
      },
    ]

    if Settings.validator.class_name == "NucsValidator"
      chart_strings.each do |cs|
        NucsFund.find_or_create_by!(value: cs[:fund])
        NucsDepartment.find_or_create_by!(value: cs[:department])
        NucsAccount.find_or_create_by!(value: cs[:account]) if cs[:account]
        NucsProjectActivity.find_or_create_by!(project: cs[:project], activity: cs[:activity])
        NucsGl066.find_or_create_by!(cs)
      end
    end

    order = 1
    pgnu = pgex = nil

    Settings.price_group.name.to_hash.each do |k, v|
      price_group = PriceGroup.find_or_initialize_by(name: v) do |pg|
        pg.is_internal = (k == :base || k == :cancer_center)
        pg.display_order = order
      end

      price_group.save(validate: false) # override facility validator

      if k == :base
        pgnu = price_group
      elsif k == :external
        pgex = price_group
      end

      order += 1
    end

    fa = FacilityAccount.find_or_initialize_by(facility_id: facility.id) do |facility_account|
      facility_account.account_number = "123-1234567-12345678"
      facility_account.revenue_account = "50617"
      facility_account.is_active = true
      facility_account.created_by = 1
    end
    fa.save(validate: false) # specifically to skip account_number validations

    item = Item.find_or_create_by!(url_name: "example-item") do |example_item|
      example_item.facility_id = facility.id
      example_item.account = "75340"
      example_item.name = "Example Item"
      example_item.description = "<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus non ipsum id odio cursus euismod eu bibendum nisl. Sed nec.</p>"
      example_item.requires_approval = false
      example_item.initial_order_status_id = new_status.id
      example_item.is_archived = false
      example_item.is_hidden = false
      example_item.facility_account_id = fa.id
    end

    service = Service.find_or_create_by!(url_name: "example-service") do |example_service|
      example_service.facility_id = facility.id
      example_service.account = "75340"
      example_service.name = "Example Service"
      example_service.description = "<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus non ipsum id odio cursus euismod eu bibendum nisl. Sed nec.</p>"
      example_service.requires_approval = false
      example_service.initial_order_status_id = in_process.id
      example_service.is_archived = false
      example_service.is_hidden = false
      example_service.facility_account_id = fa.id
    end

    instrument = Instrument.find_or_create_by!(url_name: "example-instrument") do |example_instrument|
      example_instrument.facility_id = facility.id
      example_instrument.account = "75340"
      example_instrument.name = "Example Instrument"
      example_instrument.description = "<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus non ipsum id odio cursus euismod eu bibendum nisl. Sed nec.</p>"
      example_instrument.initial_order_status_id = new_status.id
      example_instrument.requires_approval = false
      example_instrument.is_archived = false
      example_instrument.is_hidden = false
      example_instrument.facility_account_id = fa.id
      example_instrument.reserve_interval = 5
    end

    RelaySynaccessRevB.find_or_create_by!(instrument_id: instrument.id) do |relay_instrument|
      relay_instrument.ip = "192.168.10.135"
      relay_instrument.outlet = "1"
      relay_instrument.username = "admin"
      relay_instrument.password = "admin"
    end

    bundle = Bundle.find_by(url_name: "example-bundle")

    unless bundle
      bundle = Bundle.create!(facility_id: facility.id,
                              account: "75340",
                              name: "Example Bundle",
                              url_name: "example-bundle",
                              description: "<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus non ipsum id odio cursus euismod eu bibendum nisl. Sed nec.</p>",
                              requires_approval: false,
                              is_archived: false,
                              is_hidden: false,
                              facility_account_id: fa.id)
    end

    BundleProduct.create(bundle: bundle, product: item, quantity: 1)
    BundleProduct.create(bundle: bundle, product: service, quantity: 1)

    @item          = item
    @service       = service
    @instrument    = instrument
    @bundle        = bundle

    sr = ScheduleRule.find_or_create_by!(product: instrument) do |schedule_rule|
      schedule_rule.discount_percent = 0
      schedule_rule.start_hour = 8
      schedule_rule.start_min = 0
      schedule_rule.end_hour = 19
      schedule_rule.end_min = 0
      schedule_rule.on_sun = true
      schedule_rule.on_mon = true
      schedule_rule.on_tue = true
      schedule_rule.on_wed = true
      schedule_rule.on_thu = true
      schedule_rule.on_fri = true
      schedule_rule.on_sat = true
    end

    [item, service, bundle].each do |product|
      PriceGroupProduct.find_or_create_by!(price_group_id: pgnu.id, product_id: product.id)
      PriceGroupProduct.find_or_create_by!(price_group_id: pgex.id, product_id: product.id)
    end

    pgp = PriceGroupProduct.find_or_create_by!(price_group_id: pgnu.id, product_id: instrument.id)
    pgp.reservation_window = 14
    pgp.save!

    pgp = PriceGroupProduct.find_or_create_by!(price_group_id: pgex.id, product_id: instrument.id)
    pgp.reservation_window = 14
    pgp.save!

    inpp = InstrumentPricePolicy.find_or_initialize_by(product_id: instrument.id, price_group_id: pgnu.id) do |price_policy|
      price_policy.can_purchase = true
      price_policy.start_date = SettingsHelper.fiscal_year_beginning
      price_policy.expire_date = SettingsHelper.fiscal_year_end
      price_policy.usage_rate = 20
      price_policy.usage_subsidy = 0
      price_policy.minimum_cost = 0
      price_policy.cancellation_cost = 0
      price_policy.charge_for = "usage"
    end

    inpp.save(validate: false) # override date validator

    itpp = ItemPricePolicy.find_or_initialize_by(product_id: item.id, price_group_id: pgnu.id) do |price_policy|
      price_policy.can_purchase = true
      price_policy.start_date = 1.year.ago
      price_policy.expire_date = 1.year.from_now
      price_policy.unit_cost = 30
      price_policy.unit_subsidy = 0
    end

    itpp.save(validate: false) # override date validator

    spp = ServicePricePolicy.find_or_initialize_by(product_id: service.id, price_group_id: pgnu.id) do |price_policy|
      price_policy.can_purchase = true
      price_policy.start_date = 1.year.ago
      price_policy.expire_date = 1.year.from_now
      price_policy.unit_cost = 75
      price_policy.unit_subsidy = 0
    end

    spp.save(validate: false) # override date validator

    user_admin = User.find_by(username: "admin@example.com")
    unless user_admin
      user_admin = User.new(username: "admin@example.com",
                            email: "admin@example.com",
                            first_name: "Admin",
                            last_name: "Istrator")
      user_admin.password = "password"
      user_admin.save!
      UserRole.grant(user_admin, UserRole::ADMINISTRATOR)
    end

    user_pi = User.find_by(username: "ppi123@example.com")
    unless user_pi
      user_pi = User.new(username: "ppi123@example.com",
                         email: "ppi123@example.com",
                         first_name: "Paul",
                         last_name: "PI")
      user_pi.password = "password"
      user_pi.save!
    end

    user_student = User.find_by(username: "sst123@example.com")
    unless user_student
      user_student = User.new(username: "sst123@example.com",
                              email: "sst123@example.com",
                              first_name: "Sam",
                              last_name: "Student")
      user_student.password = "password"
      user_student.save!
    end

    user_staff = User.find_by(username: "ast123@example.com")
    unless user_staff
      user_staff = User.new(username: "ast123@example.com",
                            email: "ast123@example.com",
                            first_name: "Alice",
                            last_name: "Facility Staff")
      user_staff.password = "password"
      user_staff.save!
      UserRole.grant(user_staff, UserRole::FACILITY_STAFF, facility)
    end

    user_senior_staff = User.find_by(username: "jss123@example.com")
    unless user_senior_staff
      user_senior_staff = User.new(username: "jss123@example.com",
                                   email: "jss123@example.com",
                                   first_name: "Jennifer",
                                   last_name: "Facility Senior Staff")
      user_senior_staff.password = "password"
      user_senior_staff.save!
      UserRole.grant(user_senior_staff, UserRole::FACILITY_SENIOR_STAFF, facility)
    end

    user_facility_administrator = User.find_by(username: "mfa123@example.com")
    unless user_facility_administrator
      user_facility_administrator = User.new(username: "mfa123@example.com",
                                             email: "mfa123@example.com",
                                             first_name: "Macy",
                                             last_name: "Facility Administator")
      user_facility_administrator.password = "password"
      user_facility_administrator.save!
      UserRole.grant(user_facility_administrator, UserRole::FACILITY_ADMINISTRATOR, facility)
    end

    user_director = User.find_by(username: "ddi123@example.com")
    unless user_director
      user_director = User.new(username: "ddi123@example.com",
                               email: "ddi123@example.com",
                               first_name: "Dave",
                               last_name: "Facililty Director")
      user_director.password = "password"
      user_director.save
      UserRole.grant(user_director, UserRole::FACILITY_DIRECTOR, facility)
    end

    user_account_manager = User.find_by(username: "aam123@example.com")
    unless user_account_manager
      user_account_manager = User.new(username: "aam123@example.com",
                                      email: "aam123@example.com",
                                      first_name: "Ava",
                                      last_name: "Account Manager")
      user_account_manager.password = "password"
      user_account_manager.save!
      UserRole.grant(user_account_manager, UserRole::ACCOUNT_MANAGER)
    end

    if SettingsHelper.feature_on?(:global_billing_administrator)
      user_global_billing_administrator = User.find_by(email: "bba123@example.com")
      if user_global_billing_administrator.blank?
        user_global_billing_administrator = User.new(username: "bba123@example.com",
                                                     email: "bba123@example.com",
                                                     first_name: "Billy",
                                                     last_name: "Global Billing Administator")
        user_global_billing_administrator.password = "password"
        user_global_billing_administrator.save
        UserRole.grant(user_global_billing_administrator, UserRole::GLOBAL_BILLING_ADMINISTRATOR)
      end
    end

    user_facility_billing_administrator = User.find_by(username: "ffba123@example.com")
    unless user_facility_billing_administrator
      user_facility_billing_administrator = User.new(username: "ffba123@example.com",
                                                     email: "ffba123@example.com",
                                                     first_name: "Felix",
                                                     last_name: "Facility Billing Administator")
      user_facility_billing_administrator.password = "password"
      user_facility_billing_administrator.save!
      UserRole.grant(user_facility_billing_administrator, UserRole::FACILITY_BILLING_ADMINISTRATOR, facility)
    end

    UserPriceGroupMember.find_or_create_by!(user_id: user_pi.id, price_group_id: pgnu.id)
    UserPriceGroupMember.find_or_create_by!(user_id: user_student.id, price_group_id: pgnu.id)
    UserPriceGroupMember.find_or_create_by!(user_id: user_staff.id, price_group_id: pgnu.id)
    UserPriceGroupMember.find_or_create_by!(user_id: user_director.id, price_group_id: pgnu.id)

    # account creation / setup
    # see FacilityAccountsController#create

    account_owner_attributes = {
      user_id: user_pi.id,
      user_role: "Owner",
      created_by: user_director.id,
    }
    account_purchaser_attributes = {
      user_id: user_student.id,
      user_role: "Purchaser",
      created_by: user_director.id,
    }
    account_users_attributes = [
      account_owner_attributes,
      account_purchaser_attributes,
    ]
    nufs_account_attributes = {
      expires_at: 1.year.from_now,
      created_by: user_director.id,
      account_users_attributes: account_users_attributes,
    }

    nufsaccount = NufsAccount.find_by(account_number: "111-2222222-33333333-01")

    unless nufsaccount
      nufsaccount = NufsAccount.create!(
        nufs_account_attributes.merge(
          account_number: "111-2222222-33333333-01",
          description: "Paul PI's Chart String",
        ),
      )
      nufsaccount.set_expires_at
    end

    # create a second nufsaccount for split accounts
    nufsaccount2 = NufsAccount.find_by(account_number: "123-1234567-12345678-01")

    unless nufsaccount2
      nufsaccount2 = NufsAccount.create!(
        nufs_account_attributes.merge(
          account_number: "123-1234567-12345678-01",
          description: "Paul PI's Other Chart String",
        ),
      )
      nufsaccount2.set_expires_at
    end

    # create split account if the feature is enabled
    if SettingsHelper.feature_on?(:split_accounts)
      split_account = SplitAccounts::SplitAccount.find_by(account_number: "111-2222222-55555555-01")
      unless split_account

        params = {
          split_accounts_split_account: {
            account_number: "111-2222222-55555555-01",
            description: "Paul PI's 50/50 Split Account",
            splits_attributes: [
              {
                subaccount_id: nufsaccount.id,
                percent: 50,
                apply_remainder: true,
              },
              {
                subaccount_id: nufsaccount2.id,
                percent: 50,
                apply_remainder: false,
              },
            ],
          },
        }

        builder = AccountBuilder.for("SplitAccounts::SplitAccount")

        split_account = builder.new(account_type: "SplitAccounts::SplitAccount",
                                    current_user: user_director,
                                    owner_user: user_pi,
                                    params: params).build

        split_account.account_users.build(user_id: user_student.id,
                                          user_role: "Purchaser",
                                          created_by: user_director.id)

        split_account.save
      end
    end

    other_affiliate = Affiliate.OTHER

    if EngineManager.engine_loaded? :c2po
      ccaccount = CreditCardAccount.find_by(account_number: "xxxx-xxxx-xxxx-xxxx")

      unless ccaccount
        ccaccount = CreditCardAccount.create!(account_number: "xxxx-xxxx-xxxx-xxxx",
                                              description: "Paul PI's Credit Card",
                                              expires_at: Time.zone.now + 1.year,
                                              name_on_card: "Paul PI",
                                              expiration_month: "10",
                                              expiration_year: 5.years.from_now.year,
                                              created_by: user_director.id,
                                              affiliate_id: other_affiliate.id,
                                              affiliate_other: "Some Affiliate",
                                              facilities: [facility],
                                              account_users_attributes: account_users_attributes)
      end

      poaccount = PurchaseOrderAccount.find_by(account_number: "12345")

      unless poaccount
        poaccount = PurchaseOrderAccount.create!(account_number: "12345",
                                                 description: "Paul PI's Purchase Order",
                                                 expires_at: Time.zone.now + 1.year,
                                                 created_by: user_director.id,
                                                 facilities: [facility],
                                                 affiliate_id: other_affiliate.id,
                                                 affiliate_other: "Some Affiliate",
                                                 remittance_information: "Billing Dept\nEdward External\n1702 E Research Dr\nAuburn, AL 36830",
                                                 account_users_attributes: account_users_attributes)
      end
    end

    # purchased orders, complete, statements sent, 3 months ago
    sleep 2
    (1..10).each do |_i|
      order = get_order(user_student, facility, get_account(user_student), purchase: true, ordered_at: Time.zone.now - (rand(30) + 65).days) # 94-65 days in the past
      order.reload
      order.order_details.each do |od|
        # enter actuals for instruments
        set_instrument_order_actual_cost(od) if od.reservation
        od.change_status!(complete)
      end
    end
    sleep 2
    statement_date = Time.zone.now - 64.days # 64 days in the past
    accounts       = Account.need_statements(facility)
    accounts.each do |a|
      statement = Statement.create!(facility_id: facility.id, created_by: user_director.id, created_at: statement_date, account: a)
      a.update_order_details_with_statement(statement)
    end

    # purchased orders, complete, statements sent, 2 months ago
    sleep 2
    (1..10).each do |_i|
      order = get_order(user_student, facility, get_account(user_student), purchase: true, ordered_at: Time.zone.now - (rand(30) + 32).days) # 61 - 32 days in the past
      order.reload
      order.order_details.each do |od|
        # enter actuals for instruments
        set_instrument_order_actual_cost(od) if od.reservation
        od.change_status!(complete)
      end
    end
    sleep 2
    statement_date = Time.zone.now - 31.days # 31 days in the past
    accounts       = Account.need_statements(facility)
    accounts.each do |a|
      statement = Statement.create!(facility_id: facility.id, created_by: user_director.id, created_at: statement_date, account: a)
      a.update_order_details_with_statement(statement)
    end

    # purchased orders, complete details, no statement
    sleep 2
    (1..10).each do |_i|
      order = get_order(user_student, facility, get_account(user_student), purchase: true, ordered_at: Time.zone.now - (rand(30) + 1).days) # 30 - 1 days in past
      order.reload
      order.order_details.each do |od|
        # enter actuals for instruments
        set_instrument_order_actual_cost(od) if od.reservation
        od.change_status!(complete)
      end
    end

    # purchased orders, new order details, ordered at last X days
    sleep 2
    (1..5).each do |i|
      order = get_order(user_student, facility, get_account(user_student), purchase: true, ordered_at: Time.zone.now - (i * 2).days)
    end
  end

  def get_account(user)
    accounts = user.accounts.active
    accounts[rand(accounts.length)]
  end

  def get_order(user, facility, account, args = {})
    # create the order
    o = Order.create(account_id: account.id,
                     user_id: user.id,
                     facility_id: facility.id,
                     created_by: user.id)
    ordered_at = args[:ordered_at] || Time.zone.now - 60 * 60 * 24 * (rand(30) + 1)
    # create at least one order detail.  20% chance to create an additional detail.

    # create a valid order detail (with price policy and costs)
    products = [@service, @instrument, @item, @bundle]
    return nil if products.empty?
    i = 1
    begin
      product = products[rand(products.length)]
      if product.is_a?(Bundle)
        created_at = (ordered_at - (60 * rand(60) + 1))
        group_id   = (o.order_details.collect { |od| od.group_id || 0 }.max || 0) + 1
        product.bundle_products.each do |bp|
          od = OrderDetail.create!(
            created_by: o.user.id,
            order_id: o.id,
            product_id: bp.product_id,
            actual_cost: rand(2),
            actual_subsidy: 0,
            estimated_cost: rand(2),
            estimated_subsidy: 0,
            quantity: bp.quantity,
            created_at: created_at,
            bundle_product_id: product.id,
            group_id: group_id,
            order_status_id: bp.product.initial_order_status.id,
            ordered_at: ordered_at,
          )
          od.account = account
          od.save!
        end
      else
        od = OrderDetail.new(
          created_by: o.user.id,
          order_id: o.id,
          product_id: product.id,
          actual_cost: rand(2),
          actual_subsidy: 0,
          estimated_cost: rand(2),
          estimated_subsidy: 0,
          quantity: product.is_a?(Item) ? (rand(3) + 1) : 1,
          created_at: (ordered_at - (60 * rand(60) + 1)),
          order_status_id: product.initial_order_status.id,
          ordered_at: ordered_at,
        )

        # create a reservation
        if product.is_a?(Instrument)
          res = od.build_reservation(
            product_id: product.id,
            reserve_start_at: Time.zone.parse((ordered_at + 1.day).strftime("%Y-%m-%d") + " #{i + 8}:00"),
            reserve_end_at: Time.zone.parse((ordered_at + 1.day).strftime("%Y-%m-%d") + " #{i + 9}:00"),
          )
          i += 1
        end
        od.account = account

        od.price_policy = case od.product
                          when Instrument then InstrumentPricePolicy.first
                          when Item then ItemPricePolicy.first
                          when Service then ServicePricePolicy.first
                        end

        od.order_status_id ||= od.product.initial_order_status_id
        od.save!
      end
    end until rand(5) > 0

    # validate and purchase the order
    if args[:purchase]
      o.state = "validated"
      o.save(validate: false)
      o.purchase!
    end
    o.validate_order! if args[:validate]
    o
  end

  def set_instrument_order_actual_cost(order_detail)
    res = order_detail.reservation
    res.actual_start_at = res.reserve_start_at
    res.actual_end_at   = res.reserve_end_at
    res.save(validate: false)
    costs = order_detail.price_policy.calculate_cost_and_subsidy(res)
    order_detail.actual_cost    = costs[:cost]
    order_detail.actual_subsidy = costs[:subsidy]
    order_detail.save!
  end
end
