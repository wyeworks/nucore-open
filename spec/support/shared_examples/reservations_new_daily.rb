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
    expect(instrument.daily_booking?).to be true

    visit reservation_path

    # Form and open hour table to be axe clean
    expect(page).to be_axe_clean.within(".simple_form")
    expect(page).to be_axe_clean.within(".open-hours")

    expect(page).to have_content("Create Reservation")
    expect(page).to have_content("Reserve Start")
    expect(page).to have_content("Reserve End")
    expect(page).to have_content("Duration Days")

    # Start time availability table is present
    expect(page).to have_xpath("//table/tbody/tr/th[text()='Start Time Availability']")

    # Calendar is rendered with correct view
    expect(page).to have_xpath("//div[@id='calendar'][@data-default-view='month']")

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

# Examples that create a reservation with a daily booking
# instrument with start time disabled.
#
# See "new daily reservation" shared examples to
# see requirements
#
RSpec.shared_examples "new daily reservation with start time disabled" do |before_submit: nil, after_submit: nil|
  it "creates a reservation" do
    expect(instrument.daily_booking?).to be true
    expect(instrument.start_time_disabled?).to be true

    visit reservation_path

    expect(page).to have_content("Reserve Start")
    expect(page).to have_content("Reserve End")
    expect(page).to have_content("Duration Days")

    expect(page).to_not have_field("reservation[reserve_start_hour]")
    expect(page).to_not have_field("reservation[reserve_start_min]")
    expect(page).to_not have_field("reservation[reserve_start_meridian]")

    expect(page).to_not have_content("Start Time Availability")

    fill_in("Reserve Start", with: I18n.l(1.day.from_now.to_date, format: :usa))

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
