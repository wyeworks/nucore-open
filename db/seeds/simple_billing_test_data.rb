# frozen_string_literal: true

# Simple script to create minimal test data for billing log payment source search
# Run in rails console: load 'db/seeds/simple_billing_test_data.rb'

puts "Creating simple test data..."

# Use first facility or create one
facility = Facility.first
unless facility
  puts "No facility found. Please create one first with: Facility.create!(name: 'Test', abbreviation: 'TEST')"
  exit
end

# Use first product or create simple one
product = facility.products.first
unless product
  product = Item.create!(
    facility: facility,
    name: "Test Item",
    url_name: "test-item-#{Time.current.to_i}",
    account_id: 1  # Use a valid account ID
  )
end

# Create a test user
user = User.find_or_create_by!(email: "billing_test@example.com") do |u|
  u.first_name = "Billing"
  u.last_name = "Test"
  u.username = "billing_test"
end

# Create test account - first add the account owner, then create account
account = NufsAccount.find_by(account_number: "BILLING-TEST-001")
unless account
  account = NufsAccount.new(
    account_number: "BILLING-TEST-001",
    description: "Billing Test Account",
    expires_at: 1.year.from_now,
    created_by: user.id
  )
  account.save(validate: false)  # Skip validation temporarily
  
  # Now add the account owner
  AccountUser.create!(account: account, user: user, user_role: "Owner", created_by: user.id)
  
  # Save again with validation
  account.save!
end

# Create statements with different dates
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

# Create orders
order1 = Order.create!(
  facility: facility,
  user: user,
  created_by: user.id,
  account: account
)

order2 = Order.create!(
  facility: facility,
  user: user,
  created_by: user.id,
  account: account
)

# Create order details with deposit numbers
OrderDetail.create!(
  order: order1,
  product: product,
  statement: statement1,
  deposit_number: "CHECK-001",
  quantity: 1,
  actual_cost: 100.00,
  estimated_cost: 100.00
)

OrderDetail.create!(
  order: order1,
  product: product,
  statement: statement1,
  deposit_number: "CHECK-002",
  quantity: 1,
  actual_cost: 50.00,
  estimated_cost: 50.00
)

OrderDetail.create!(
  order: order2,
  product: product,
  statement: statement2,
  deposit_number: "WIRE-TRANSFER-123",
  quantity: 1,
  actual_cost: 200.00,
  estimated_cost: 200.00
)

OrderDetail.create!(
  order: order2,
  product: product,
  statement: statement2,
  deposit_number: nil,  # One without deposit number
  quantity: 1,
  actual_cost: 75.00,
  estimated_cost: 75.00
)

# Create log events for the statements
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

puts "\n✅ Test data created!"
puts "\nStatements created:"
puts "  - #{statement1.invoice_number} (has CHECK-001, CHECK-002)"
puts "  - #{statement2.invoice_number} (has WIRE-TRANSFER-123)"
puts "\nTest searches:"
puts "  - Payment Source: 'CHECK' → should find statement #{statement1.invoice_number}"
puts "  - Payment Source: 'WIRE' → should find statement #{statement2.invoice_number}"
puts "  - Payment Source: '001' → should find statement #{statement1.invoice_number}"
puts "  - Invoice Number: '#{statement1.id}' → should find statement #{statement1.invoice_number}"