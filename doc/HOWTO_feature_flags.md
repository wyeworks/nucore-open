# Feature Flags

## Style/Display

* `use_manage` Use "Use" for the link to the home page and place the Manage Facilities link on the left, or use "Home" for the link to the home page and place the Manage Facilities link to the right
* `facility_banner_notice` Allow setting a highly visible banner that will display when a user visits the facility homepage
* `daily_view` Display a public daily view for facility's reservation schedule
* `equipment_list` Display a list of instruments on facility home page
* `limit_short_description` Limit the short description section for facilities (300 characters)
* `product_list_columns` Display product lists in columns or one long list
* `azlist` Display one long list of facilities, or an alphabetized collection (only facilities that start with A, and ...a top nav to access facilities that start with other letters)
* `facility_tile_list` Display a grid view of the facility list on the home page, this will include images of the facilities, if the given facility has an image. This does not enable the ability to add or remove images from facilities -- this works independently of `facility_tile_list_admin`, though you may want to use these flags together.
* `facility_tile_list_admin` Adds the ability to add and remove images from facilities.  These images will only be displayed on the home page if `facility_tile_list` is set to true.

## Onboarding

* `devise/lock_strategy`Lock account after 5 failed attempts 
* `password_update` Allow users to update or reset password (forgot password button)

## Account Types

* `price_group` Global Price group names
* `suspend_accounts` Allow admins to suspend accounts
* `fiscal_year_begins` FY year cutoff
* `journals_may_span_fiscal_years` Allow journals to span fiscal years
* `split_accounts` Split accounts
* `Account.config.facility_account_types` Which account types (CC, PO) can be used at multiple facilities or just one (CC + PO should be available cross-facility)
* `facility_payment_urls` Store a payment url for each facility (can be used on statement PDFs to direct users to pay via CC)
* `default_journal_cutoff_time` Journal cutoff time
* `statement_pdf:class_name` PDF Statement formatting
* `po_require_affiliate_account` Whether or not Purchase Order accounts will be required to have affiliates

## Billing and Pricing

* `order_detail_price_change_reason_options` Require a reason when any line item's price is changed manually.  Can offer a list of reasons to choose from or text input
* `price_policy_note_options` Require a note when adding new price rules
* `charge_full_price_on_cancellation` Allow option to charge full price on cancelation
* `facility_directors_can_manage_price_groups` Can facility directors manage price groups
* `account_reference_field` Store a reference field on accounts. Dartmouth uses this if there is something special about the account. Like is the account shared with an outside source or they only want the account used for particular reasons. It’s mainly for the odd exception that an account maybe flagged for.
* `set_statement_search_start_date` By default, show statements from the last month on the "create Statements" tab
* `user_based_price_groups` Allow assigning users to specific price groups (Internal Base Rate, External, etc).  This would allow some users to potentially get cheaper (internal) rates even if they don’t have access to internal accounts.

## Notifications

* `send_statement_emails` Send email notification when statements are created
* `order_assignment_notifications` Send a notification email when an order is assigned to staff for review
* `product_specific_contacts` Allow a different contact email for each product

## Other
* `saml: create_user` create/update saml users on login
* `create_users` Should admins be able to manually add users
* `training_requests` Allow users to request training
* `global_billing_administrator` and `global_billing_administrator_users_tab` Do you want to use global billing admins? Should they be able to manage users?
* `accounts: product_default` `accounts: revenue_account_default` Specify a default Expense account from which fees will be withdrawn; must be open on purchaser's Chart String - one default for products and one for facilities.  Optionally, these can be edited per product.
* `cross_facility_reports` Allow generating cross facility reports (does not work with SES due to attached file size limits)
* `kiosk_view` Kiosk mode - display a list of actionable reservations without logging in (optionally allow acting w/o auth)
* `reservations: grace_period`, `reservations: timeout_period`, `occupancies: timeout_period`, `billing: review_period` various grace periods, time periods, and review periods
* `active_storage` use `ActiveStorage` if `true`, or `Paperclip` if `false`
* `active_storage_for_images_only` enables `ActiveStorage` for the `DownloadableFiles::Image` module. This flag needs to be enabled even if `active_storage` is
* `auto_end_reservations_on_next_start` Automatically end previous reservations for timer/relay controlled instruments, when another user starts a new reservation.
