# frozen_string_literal: true

# Script to create test data for billing log payment source search
# Run with: rails runner db/seeds/test_billing_log_data.rb
# Or in rails console: load 'db/seeds/test_billing_log_data.rb'

puts "Creating test data for billing log payment source search..."

# Find or create a facility
facility = Facility.first || FactoryBot.create(:setup_facility, name: "Test Facility", abbreviation: "TF")
puts "Using facility: #{facility.name}"

# Find or create a product
product = facility.products.first || FactoryBot.create(:setup_item, facility: facility, name: "Test Service")
puts "Using product: #{product.name}"

# Create test users and accounts
user1 = User.find_by(email: "test_user1@example.com") || FactoryBot.create(:user, email: "test_user1@example.com", first_name: "Test", last_name: "User1")
user2 = User.find_by(email: "test_user2@example.com") || FactoryBot.create(:user, email: "test_user2@example.com", first_name: "Test", last_name: "User2")

account1 = Account.find_by(account_number: "TEST-001") || FactoryBot.create(:account, 
  :with_account_owner,
  account_number: "TEST-001",
  description: "Test Account 1",
  facility: facility
)

account2 = Account.find_by(account_number: "TEST-002") || FactoryBot.create(:account,
  :with_account_owner,
  account_number: "TEST-002", 
  description: "Test Account 2",
  facility: facility
)

puts "Created accounts: #{account1.account_number}, #{account2.account_number}"

# Create statements
statement1 = Statement.create!(
  facility: facility,
  account: account1,
  created_by: user1.id,
  created_at: 1.month.ago
)

statement2 = Statement.create!(
  facility: facility,
  account: account2,
  created_by: user2.id,
  created_at: 2.weeks.ago
)

statement3 = Statement.create!(
  facility: facility,
  account: account1,
  created_by: user1.id,
  created_at: 1.week.ago
)

puts "Created statements: #{statement1.invoice_number}, #{statement2.invoice_number}, #{statement3.invoice_number}"

# Create orders and order details with different deposit numbers
order1 = Order.create!(
  facility: facility,
  user: user1,
  created_by_user: user1,
  account: account1,
  state: "purchased"
)

order2 = Order.create!(
  facility: facility,
  user: user2,
  created_by_user: user2,
  account: account2,
  state: "purchased"
)

order3 = Order.create!(
  facility: facility,
  user: user1,
  created_by_user: user1,
  account: account1,
  state: "purchased"
)

# Create order details with various deposit numbers
order_detail1 = OrderDetail.create!(
  order: order1,
  product: product,
  statement: statement1,
  deposit_number: "CHECK-12345",
  quantity: 1,
  actual_cost: 100.00,
  actual_subsidy: 0,
  estimated_cost: 100.00,
  estimated_subsidy: 0,
  state: "reconciled",
  reconciled_at: 1.week.ago,
  reconciled_note: "Reconciled with check payment"
)

order_detail2 = OrderDetail.create!(
  order: order1,
  product: product,
  statement: statement1,
  deposit_number: "CHECK-12346",
  quantity: 1,
  actual_cost: 50.00,
  actual_subsidy: 0,
  estimated_cost: 50.00,
  estimated_subsidy: 0,
  state: "reconciled",
  reconciled_at: 1.week.ago
)

order_detail3 = OrderDetail.create!(
  order: order2,
  product: product,
  statement: statement2,
  deposit_number: "WIRE-98765",
  quantity: 2,
  actual_cost: 200.00,
  actual_subsidy: 0,
  estimated_cost: 200.00,
  estimated_subsidy: 0,
  state: "reconciled",
  reconciled_at: 5.days.ago,
  reconciled_note: "Wire transfer received"
)

order_detail4 = OrderDetail.create!(
  order: order3,
  product: product,
  statement: statement3,
  deposit_number: "CRT-2024-001",
  quantity: 1,
  actual_cost: 75.00,
  actual_subsidy: 0,
  estimated_cost: 75.00,
  estimated_subsidy: 0,
  state: "reconciled",
  reconciled_at: 3.days.ago,
  reconciled_note: "CRT from GL008 report"
)

# Create an order detail without deposit number
order_detail5 = OrderDetail.create!(
  order: order3,
  product: product,
  statement: statement3,
  deposit_number: nil,
  quantity: 1,
  actual_cost: 25.00,
  actual_subsidy: 0,
  estimated_cost: 25.00,
  estimated_subsidy: 0,
  state: "reconciled",
  reconciled_at: 3.days.ago,
  reconciled_note: "Manual reconciliation"
)

puts "Created order details with deposit numbers:"
puts "  - #{order_detail1.deposit_number} (Statement: #{statement1.invoice_number})"
puts "  - #{order_detail2.deposit_number} (Statement: #{statement1.invoice_number})"
puts "  - #{order_detail3.deposit_number} (Statement: #{statement2.invoice_number})"
puts "  - #{order_detail4.deposit_number} (Statement: #{statement3.invoice_number})"
puts "  - No deposit number (Statement: #{statement3.invoice_number})"

# Create LogEvents for the statements
log_event1 = LogEvent.create!(
  loggable: statement1,
  event_type: "closed",
  user: user1,
  event_time: statement1.created_at
)

log_event2 = LogEvent.create!(
  loggable: statement2,
  event_type: "closed",
  user: user2,
  event_time: statement2.created_at
)

log_event3 = LogEvent.create!(
  loggable: statement3,
  event_type: "closed",
  user: user1,
  event_time: statement3.created_at
)

# Create some other log events for variety
LogEvent.create!(
  loggable: statement1,
  event_type: "create",
  user: user1,
  event_time: statement1.created_at - 1.hour
)

LogEvent.create!(
  loggable: account1,
  event_type: "create",
  user: user1,
  event_time: 2.months.ago
)

puts "\nCreated LogEvents for statements"
puts "\n" + "="*50
puts "TEST DATA CREATED SUCCESSFULLY!"
puts "="*50
puts "\nYou can now test the billing log search with:"
puts "  - Invoice numbers: #{statement1.invoice_number}, #{statement2.invoice_number}, #{statement3.invoice_number}"
puts "  - Payment sources (deposit numbers):"
puts "    * 'CHECK' - should find 2 order details in statement #{statement1.invoice_number}"
puts "    * 'WIRE' - should find 1 order detail in statement #{statement2.invoice_number}"
puts "    * 'CRT' - should find 1 order detail in statement #{statement3.invoice_number}"
puts "    * '12345' - should find CHECK-12345"
puts "    * 'wire-98' - partial match should find WIRE-98765"
puts "\nNavigate to: /facilities/#{facility.id}/billing/log_events"