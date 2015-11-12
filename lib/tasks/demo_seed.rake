# This file contains a base set of data appropriate for development or testing.
# The data can then be loaded with the rake db:bi_seed.
#
# !!!! BE AWARE that ActiveRecord's #find_or_create_by... methods do not
# always work properly! You're better off doing a #find_by, checking
# the return's existence, and creating if necessary !!!!
namespace :demo do
  desc "bootstrap db with data appropriate for demonstration"

  task seed: :environment do
    new_status = OrderStatus.find_or_create_by_name(name: "New")
    in_process = OrderStatus.find_or_create_by_name(name: "In Process")
    canceled   = OrderStatus.find_or_create_by_name(name: "Canceled")
    complete   = OrderStatus.find_or_create_by_name(name: "Complete")
    reconciled = OrderStatus.find_or_create_by_name(name: "Reconciled")

    facility = Facility.find_or_create_by_name(name: "Example Facility",
                                               abbreviation: "EF",
                                               url_name: "example",
                                               short_description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam in mi tellus. Nunc ut turpis rhoncus mauris vehicula volutpat in fermentum metus. Sed eleifend purus at nunc facilisis fermentum metus.",
                                               description: "<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris scelerisque metus et augue elementum ac pellentesque neque blandit. Nunc ultrices auctor velit, et ullamcorper lacus ultrices id. Pellentesque vulputate dapibus mauris, sollicitudin mollis diam malesuada nec. Fusce turpis augue, consectetur nec consequat nec, tristique sit amet urna. Nunc vitae imperdiet est. Aenean gravida, risus eget posuere fermentum, risus odio bibendum ligula, sit amet lobortis enim odio facilisis ipsum. Donec iaculis dolor vitae massa ullamcorper pulvinar. In hac habitasse platea dictumst. Pellentesque iaculis sapien id est auctor a semper odio tincidunt. Suspendisse nec lectus sit amet est imperdiet elementum non sagittis nulla. Sed tempor velit nec sapien rhoncus consequat semper neque malesuada. Nunc gravida justo in felis tempus dapibus. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Duis tristique diam dolor. Curabitur lacinia molestie est vel mollis. Ut facilisis vestibulum scelerisque. Aenean placerat purus in nisi auctor scelerisque.</p>",
                                               address: "Example Facility\nFinancial Dept\n111 University Rd.\nEvanston, IL 60201-0111",
                                               phone_number: "(312) 123-4321",
                                               fax_number: "(312) 123-1234",
                                               email: "example-support@example.com",
                                               is_active: true)

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
        NucsFund.find_or_create_by_value(cs[:fund])
        NucsDepartment.find_or_create_by_value(cs[:department])
        NucsAccount.find_or_create_by_value(cs[:account]) if cs[:account]
        NucsProjectActivity.find_or_create_by_project_and_activity(project: cs[:project], activity: cs[:activity])
        NucsGl066.find_or_create_by_fund_and_department_and_project_and_account(cs)
      end
    end

    order = 1
    pgnu = pgex = nil

    Settings.price_group.name.to_hash.each do |k, v|
      price_group = PriceGroup.find_or_create_by_name(name: v, is_internal: (k == :base || k == :cancer_center), display_order: order)

      price_group.save(validate: false) # override facility validator

      if k == :base
        pgnu = price_group
      elsif k == :external
        pgex = price_group
      end

      order += 1
    end

    fa = FacilityAccount.find_or_create_by_facility_id(facility_id: facility.id,
                                                       account_number: "123-1234567-12345678",
                                                       revenue_account: "50617",
                                                       is_active: 1,
                                                       created_by: 1)

    item = Item.find_or_create_by_url_name(facility_id: facility.id,
                                           account: "75340",
                                           name: "Example Item",
                                           url_name: "example-item",
                                           description: "<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus non ipsum id odio cursus euismod eu bibendum nisl. Sed nec.</p>",
                                           requires_approval: false,
                                           initial_order_status_id: new_status.id,
                                           is_archived: false,
                                           is_hidden: false,
                                           facility_account_id: fa.id)

    service = Service.find_or_create_by_url_name(facility_id: facility.id,
                                                 account: "75340",
                                                 name: "Example Service",
                                                 url_name: "example-service",
                                                 description: "<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus non ipsum id odio cursus euismod eu bibendum nisl. Sed nec.</p>",
                                                 requires_approval: false,
                                                 initial_order_status_id: in_process.id,
                                                 is_archived: false,
                                                 is_hidden: false,
                                                 facility_account_id: fa.id)

    instrument = Instrument.find_or_create_by_url_name(facility_id: facility.id,
                                                       account: "75340",
                                                       name: "Example Instrument",
                                                       url_name: "example-instrument",
                                                       description: "<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus non ipsum id odio cursus euismod eu bibendum nisl. Sed nec.</p>",
                                                       initial_order_status_id: new_status.id,
                                                       requires_approval: false,
                                                       is_archived: false,
                                                       is_hidden: false,
                                                       facility_account_id: fa.id,
                                                       reserve_interval: 5)

    RelaySynaccessRevB.find_or_create_by_instrument_id(instrument_id: instrument.id,
                                                       ip: "192.168.10.135",
                                                       port: "1",
                                                       username: "admin",
                                                       password: "admin")

    bundle = Bundle.find_by_url_name "example-bundle"

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

    sr = ScheduleRule.find_or_create_by_instrument_id(instrument_id: instrument.id,
                                                      discount_percent: 0,
                                                      start_hour: 8,
                                                      start_min: 0,
                                                      end_hour: 19,
                                                      end_min: 0,
                                                      on_sun: true,
                                                      on_mon: true,
                                                      on_tue: true,
                                                      on_wed: true,
                                                      on_thu: true,
                                                      on_fri: true,
                                                      on_sat: true)

    [item, service, bundle].each do |product|
      PriceGroupProduct.find_or_create_by_price_group_id_and_product_id(pgnu.id, product.id)
      PriceGroupProduct.find_or_create_by_price_group_id_and_product_id(pgex.id, product.id)
    end

    pgp = PriceGroupProduct.find_or_create_by_price_group_id_and_product_id(pgnu.id, instrument.id)
    pgp.reservation_window = 14
    pgp.save!

    pgp = PriceGroupProduct.find_or_create_by_price_group_id_and_product_id(pgex.id, instrument.id)
    pgp.reservation_window = 14
    pgp.save!

    inpp = InstrumentPricePolicy.find_or_create_by_product_id_and_price_group_id(can_purchase: true,
                                                                                 product_id: instrument.id,
                                                                                 price_group_id: pgnu.id,
                                                                                 start_date: SettingsHelper.fiscal_year_beginning,
                                                                                 expire_date: SettingsHelper.fiscal_year_end,
                                                                                 usage_rate: 20,
                                                                                 usage_subsidy: 0,
                                                                                 minimum_cost: 0,
                                                                                 cancellation_cost: 0,
                                                                                 charge_for: "usage")
    inpp.save(validate: false) # override date validator

    itpp = ItemPricePolicy.find_or_create_by_product_id_and_price_group_id(can_purchase: true,
                                                                           product_id: item.id,
                                                                           price_group_id: pgnu.id,
                                                                           start_date: Time.zone.now - 1.year,
                                                                           expire_date: Time.zone.now + 1.year,
                                                                           unit_cost: 30,
                                                                           unit_subsidy: 0)
    itpp.save(validate: false) # override date validator

    spp = ServicePricePolicy.find_or_create_by_product_id_and_price_group_id(can_purchase: true,
                                                                             product_id: service.id,
                                                                             price_group_id: pgnu.id,
                                                                             start_date: Time.zone.now - 1.year,
                                                                             expire_date: Time.zone.now + 1.year,
                                                                             unit_cost: 75,
                                                                             unit_subsidy: 0)
    spp.save(validate: false) # override date validator

    user_admin = User.find_by_username("admin@example.com")
    unless user_admin
      user_admin = User.new(username: "admin@example.com",
                            email: "admin@example.com",
                            first_name: "Admin",
                            last_name: "Istrator")
      user_admin.password = "password"
      user_admin.save!
    end
    UserRole.grant(user_admin, UserRole::ADMINISTRATOR)

    user_pi = User.find_by_username("ppi123@example.com")
    unless user_pi
      user_pi = User.new(username: "ppi123@example.com",
                         email: "ppi123@example.com",
                         first_name: "Paul",
                         last_name: "PI")
      user_pi.password = "password"
      user_pi.save!
    end

    user_student = User.find_by_username("sst123@example.com")
    unless user_student
      user_student = User.new(username: "sst123@example.com",
                              email: "sst123@example.com",
                              first_name: "Sam",
                              last_name: "Student")
      user_student.password = "password"
      user_student.save!
    end

    user_staff = User.find_by_username("ast123@example.com")
    unless user_staff
      user_staff = User.new(username: "ast123@example.com",
                            email: "ast123@example.com",
                            first_name: "Alice",
                            last_name: "Staff")
      user_staff.password = "password"
      user_staff.save!
    end
    UserRole.grant(user_staff, UserRole::FACILITY_STAFF, facility)

    user_director = User.find_by_username("ddi123@example.com")
    unless user_director
      user_director = User.new(username: "ddi123@example.com",
                               email: "ddi123@example.com",
                               first_name: "Dave",
                               last_name: "Director")
      user_director.password = "password"
      user_director.save
    end

    user_billing_administrator = User.find_by_email("bba123@example.com")
    unless user_billing_administrator
      user_billing_administrator = User.new(username: "bba123@example.com",
                                            email: "bba123@example.com",
                                            first_name: "Billy",
                                            last_name: "Billing",
                                           )
      user_billing_administrator.password = "password"
      user_billing_administrator.save
    end

    UserRole.grant(user_director, UserRole::FACILITY_DIRECTOR, facility)

    UserRole.grant(user_billing_administrator, UserRole::BILLING_ADMINISTRATOR)

    UserPriceGroupMember.find_or_create_by_user_id_and_price_group_id(user_id: user_pi.id,
                                                                      price_group_id: pgnu.id)
    UserPriceGroupMember.find_or_create_by_user_id_and_price_group_id(user_id: user_student.id,
                                                                      price_group_id: pgnu.id)
    UserPriceGroupMember.find_or_create_by_user_id_and_price_group_id(user_id: user_staff.id,
                                                                      price_group_id: pgnu.id)
    UserPriceGroupMember.find_or_create_by_user_id_and_price_group_id(user_id: user_director.id,
                                                                      price_group_id: pgnu.id)

    # account creation / setup
    # see FacilityAccountsController#create
    nufsaccount = NufsAccount.find_by_account_number("111-2222222-33333333-01")

    unless nufsaccount
      nufsaccount = NufsAccount.create!(account_number: "111-2222222-33333333-01",
                                        description: "Paul PI's Chart String",
                                        expires_at: Time.zone.now + 1.year,
                                        created_by: user_director.id,
                                        account_users_attributes: [
                                          { user_id: user_pi.id, user_role: "Owner", created_by: user_director.id },
                                          { user_id: user_student.id, user_role: "Purchaser", created_by: user_director.id },
                                        ])
      nufsaccount.set_expires_at!
    end

    other_affiliate = Affiliate.find_or_create_by_name("Other")

    if EngineManager.engine_loaded? :c2po
      ccaccount = CreditCardAccount.find_by_account_number("xxxx-xxxx-xxxx-xxxx")

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
                                              account_users_attributes: [
                                                { user_id: user_pi.id, user_role: "Owner", created_by: user_director.id },
                                                { user_id: user_student.id, user_role: "Purchaser", created_by: user_director.id },
                                              ])
      end

      poaccount = PurchaseOrderAccount.find_by_account_number("12345")

      unless poaccount
        poaccount = PurchaseOrderAccount.create!(account_number: "12345",
                                                 description: "Paul PI's Purchase Order",
                                                 expires_at: Time.zone.now + 1.year,
                                                 created_by: user_director.id,
                                                 facility_id: facility.id,
                                                 affiliate_id: other_affiliate.id,
                                                 affiliate_other: "Some Affiliate",
                                                 remittance_information: "Billing Dept\nEdward External\n1702 E Research Dr\nAuburn, AL 36830",
                                                 account_users_attributes: [
                                                   { user_id: user_pi.id, user_role: "Owner", created_by: user_director.id },
                                                   { user_id: user_student.id, user_role: "Purchaser", created_by: user_director.id },
                                                 ])
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
          od = OrderDetail.create!(created_by: o.user.id,
                                   order_id: o.id,
                                   product_id: bp.product_id,
                                   actual_cost: rand(2),
                                   actual_subsidy: 0,
                                   estimated_cost: rand(2),
                                   estimated_subsidy: 0,
                                   quantity: bp.quantity,
                                   created_at: created_at,
                                   bundle_product_id: product.id,
                                   group_id: group_id)
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
      o.update_attributes!(ordered_at: ordered_at)
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

  def dump_record(model)
    if model.new_record?
      puts "#{model.class.name} CREATE FAILED!"
      model.errors.full_messages.each { |m| puts m }
    end
  end
end
