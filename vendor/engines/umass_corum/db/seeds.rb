PriceGroup.create_with(is_internal: true, admin_editable: false, display_order: 4)
  .find_or_initialize_by(name: "Other academic (UMass Affiliated)").save!(validate: false)
PriceGroup.create_with(is_internal: false, admin_editable: false, display_order: 3)
  .find_or_initialize_by(name: "Other academic (Non-UMass Affiliated)").save!(validate: false)

FactoryBot.create(:api_speed_type, speed_type: "123456")
FactoryBot.create(:api_speed_type, speed_type: "654321")
