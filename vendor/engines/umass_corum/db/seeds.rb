PriceGroup.setup_global(
  name: "Other academic (UMass Affiliated)",
  is_internal: true,
  admin_editable: false,
  display_order: 4
)

PriceGroup.setup_global(
  name: "Other academic (Non-UMass Affiliated)",
  is_internal: false,
  admin_editable: false,
  display_order: 3
)

FactoryBot.create(:api_speed_type, speed_type: "123456")
FactoryBot.create(:api_speed_type, speed_type: "654321")
