# frozen_string_literal: true

# Very simple script to create test data for billing log
# Run: rails runner db/seeds/very_simple_billing_test.rb

puts "Creating test data for deposit_number search..."

# Use existing facility and product
facility = Facility.first
product = facility.products.first if facility

if !facility || !product
  puts "ERROR: No facility or product found. Please ensure basic data exists."
  exit
end

# Use an existing account with an owner
account = Account.joins(:account_users).where(account_users: { user_role: "Owner" }).first

if !account
  puts "ERROR: No account with owner found. Please create one first."
  exit
end

user = account.owner_user

puts "Using:"
puts "  Facility: #{facility.name}"
puts "  Product: #{product.name}"
puts "  Account: #{account.account_number}"
puts "  User: #{user.email}"

# Create statements
statement1 = Statement.create!(
  facility: facility,
  account: account,
  created_by: user.id,
  created_at: 2.weeks.ago
)

statement2 = Statement.create!(
  facility: facility,
  account: account,
  created_by: user.id,
  created_at: 1.week.ago
)

puts "\nCreated statements:"
puts "  #{statement1.invoice_number}"
puts "  #{statement2.invoice_number}"

# Create orders
order1 = Order.create!(
  facility: facility,
  user: user,
  created_by_user: user,
  account: account
)

order2 = Order.create!(
  facility: facility,
  user: user,
  created_by_user: user,
  account: account
)

# Create order details with deposit numbers
od1 = OrderDetail.create!(
  order: order1,
  product: product,
  statement: statement1,
  deposit_number: "CHECK-001",
  quantity: 1,
  actual_cost: 100.00,
  estimated_cost: 100.00,
  created_by: user.id
)

od2 = OrderDetail.create!(
  order: order1,
  product: product,
  statement: statement1,
  deposit_number: "CHECK-002",
  quantity: 1,
  actual_cost: 50.00,
  estimated_cost: 50.00,
  created_by: user.id
)

od3 = OrderDetail.create!(
  order: order2,
  product: product,
  statement: statement2,
  deposit_number: "WIRE-TRANSFER-999",
  quantity: 1,
  actual_cost: 200.00,
  estimated_cost: 200.00,
  created_by: user.id
)

od4 = OrderDetail.create!(
  order: order2,
  product: product,
  statement: statement2,
  deposit_number: "CRT-2024-123",
  quantity: 1,
  actual_cost: 75.00,
  estimated_cost: 75.00,
  created_by: user.id
)

# Create one without deposit number
od5 = OrderDetail.create!(
  order: order2,
  product: product,
  statement: statement2,
  deposit_number: nil,
  quantity: 1,
  actual_cost: 25.00,
  estimated_cost: 25.00,
  created_by: user.id
)

puts "\nCreated OrderDetails with deposit_numbers:"
puts "  Statement #{statement1.invoice_number}:"
puts "    - #{od1.deposit_number}"
puts "    - #{od2.deposit_number}"
puts "  Statement #{statement2.invoice_number}:"
puts "    - #{od3.deposit_number}"
puts "    - #{od4.deposit_number}"
puts "    - (one with no deposit_number)"

# Create log events
LogEvent.create!(
  loggable: statement1,
  event_type: "closed",
  user: user,
  event_time: statement1.created_at
)

LogEvent.create!(
  loggable: statement2,
  event_type: "closed",
  user: user,
  event_time: statement2.created_at
)

puts "\n" + "="*50
puts "SUCCESS! Test data created."
puts "="*50
puts "\nTest the search at: /facilities/#{facility.id}/billing/log_events"
puts "\nTry searching for:"
puts "  Payment Source: 'CHECK' → should find statement #{statement1.invoice_number}"
puts "  Payment Source: 'WIRE' → should find statement #{statement2.invoice_number}"
puts "  Payment Source: 'CRT' → should find statement #{statement2.invoice_number}"
puts "  Payment Source: '001' → should find CHECK-001 in statement #{statement1.invoice_number}"
puts "  Invoice Number: '#{statement1.id}' → should find statement #{statement1.invoice_number}"