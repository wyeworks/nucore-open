cancer_center = PriceGroup.find_by(name: Settings.price_group.name.cancer_center)
if cancer_center
  cancer_center.price_policies.delete_all
  cancer_center.delete
end

PriceGroup.create_with(is_internal: true, admin_editable: false, display_order: 4)
  .find_or_initialize_by(name: "Other academic (UMass Affiliated)").save!(validate: false)
PriceGroup.create_with(is_internal: false, admin_editable: false, display_order: 3)
  .find_or_initialize_by(name: "Other academic (Non-UMass Affiliated)").save!(validate: false)
