# frozen_string_literal: true

# Fill form and test daily reservation creation
#
# Hereafter are the variables (defined with let) that used.
#
# Required:
# - facility
# - instrument, a product with daily booking
# - reservation_path, the path of the reservation form
#
# Optional:
# - success_message: message to expect on success
#
# Examples params:
# - before_submit: proc to be called before submitting
# - after_submit: proc to be called after submitting
#
RSpec.shared_examples "new daily reservation" do |before_submit: nil, after_submit: nil|
  it "creates a daily reservation", :js do
    visit reservation_path

    expect(page).to have_content("Create Reservation")
    expect(page).to have_content("Duration days")

    start_date = 1.day.from_now.to_date
    start_hour = "6"
    end_date = 2.days.from_now.to_date
    duration_days = 1

    fill_in("reservation[reserve_start_date]", with: I18n.l(start_date, format: :usa))
    fill_in("reservation[duration_days]", with: duration_days)

    select(start_hour, from: "reservation[reserve_start_hour]")

    # Fields automatically updated with js
    find_field("reservation[reserve_end_date]", disabled: true).tap do |field|
      expect(field.value).to eq(I18n.l(end_date, format: :usa))
    end
    find_field("reservation[reserve_end_hour]", disabled: true).tap do |field|
      expect(field.value).to eq(start_hour)
    end

    instance_eval(&before_submit) if before_submit.present?

    click_button("Create")

    expect(page).to have_content(
      if defined?(success_message)
        success_message
      else
        "Reservation created successfully"
      end
    )

    instance_eval(&after_submit) if after_submit.present?
  end
end
