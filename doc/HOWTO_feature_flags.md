# Feature Flags

## Style/Display

* `azlist` Display one long list of facilities, or an alphabetized collection (only facilities that start with A, and ...a top nav to access facilities that start with other letters)
* `daily_view` Display a public daily view for facility's reservation schedule
* `equipment_list` Display a list of instruments on facility home page
* `facility_banner_notice` Allow setting a highly visible banner that will display when a user visits the facility homepage
* `facility_tile_list_admin` Adds the ability to add and remove images from facilities.  These images will only be displayed on the home page if `facility_tile_list` is set to true.
* `facility_tile_list` Display a grid view of the facility list on the home page, this will include images of the facilities, if the given facility has an image. This does not enable the ability to add or remove images from facilities -- this works independently of `facility_tile_list_admin`, though you may want to use these flags together.
* `limit_short_description` Limit the short description section for facilities (300 characters)
* `product_list_columns` Display product lists in columns or one long list
* `use_manage` Use "Use" for the link to the home page and place the Manage Facilities link on the left, or use "Home" for the link to the home page and place the Manage Facilities link to the right

## Users and Authentication

* `create_users` Should admins be able to manually add users
* `devise/lock_strategy`Lock account after 5 failed attempts 
* `lookup_netids`: If enabled, allow internal and external users to be created and add additional step to ensure the NetId or email is not already present. Else, navigate to create external user (no internal user creation allowed).
* `password_update` Allow users to update or reset password (forgot password button)
* `saml: create_user` create/update saml users on login
* `uses_ldap_authentication`: Enable if ldap authentication engine is used and configured.

## Roles

* `allow_global_billing_admin_update_actual_prices`: Allow global billing administrators to update order details actual costs.
* `global_billing_administrator` and `global_billing_administrator_users_tab` Do you want to use global billing admins? Should they be able to manage users?
* `move_transactions_account_roles`: Allow account administrator to reassign account on order details.

## Accounts and Account Types

* `Account.config.facility_account_types` Which account types (CC, PO) can be used at multiple facilities or just one (CC + PO should be available cross-facility)
* `account_reference_field`: Enable account `reference` field.
* `account_tabs`: Display Accounts in two tabs: active and expired. Include some extra filters.
* `edit_accounts`: Allow to edit accounts.
* `expense_accounts`: Allow to set `revenue_account` on Facility Account. Else take it from `Settings.account.revenue_account_default`.
* `facility_payment_urls` Store a payment url for each facility (can be used on statement PDFs to direct users to pay via CC)
* `hide_account_far_future_expiration`: Hide expiration dates on accounts tables if they are more than 75 years in the future.
* `multi_facility_accounts`: Allow Facility Accounts to be used in various Facilities.
* `po_require_affiliate_account` Whether or not Purchase Order accounts will be required to have affiliates
* `purchase_order_monetary_cap`: Enable informational field "Monetary Cap" on purchase orders.
* `revenue_account_editable`: Allow to edit Facility Account's revenue account.
* `show_account_opencontract_field`: Show additional informational field on Accounts
* `show_account_price_groups_tab`: Show "Price Groups" tab in account management page.
* `split_accounts` Split accounts
* `statement_pdf:class_name` PDF Statement formatting
* `suspend_accounts` Allow admins to suspend accounts

## Price Groups and Pricing

* `can_manage_global_price_groups`: Enable global price groups management.
* `facility_directors_can_manage_price_groups` Can facility directors manage price groups
* `price_policy_requires_note`: Require note when adding price policies.
* `user_based_price_groups_exclude_purchaser`: Exclude purchaser's price groups when picking the price group of an order detail.
* `user_based_price_groups` Allow assigning users to specific price groups (Internal Base Rate, External, etc).  This would allow some users to potentially get cheaper (internal) rates even if they don’t have access to internal accounts.

## Billing

* `account_reference_field` Store a reference field on accounts. Dartmouth uses this if there is something special about the account. Like is the account shared with an outside source or they only want the account used for particular reasons. It’s mainly for the odd exception that an account maybe flagged for.
* `allow_mass_unreconciling`: Allow to unreconcile transactions in bulk.
* `billing_table_price_groups`: Show price group column on transactions tables.
* `charge_full_price_on_cancellation` Allow option to charge full price on cancelation
* `default_journal_cutoff_time` Journal cutoff time
* `fiscal_year_begins` FY year cutoff
* `journals_may_span_fiscal_years` Allow journals to span fiscal years
* `order_detail_price_change_reason_options` Require a reason when any line item's price is changed manually.  Can offer a list of reasons to choose from or text input
* `price_group` Global Price group names
* `price_policy_note_options` Require a note when adding new price rules
* `ready_for_journal_notice`: Enable "Ready for Journal" order details notice.
* `reference_statement_invoice_number`: Allow to specify a parent statement when creating one. Useful when recreating statements.
* `set_statement_search_start_date` By default, show statements from the last month on the "create Statements" tab
* `show_reconcile_credit_cards`: Enable reconcile menu for Credit Cards.
* `show_reconciliation_deposit_number`: Enable reconciliation deposit number field and show it in transaction listings.

## Notifications

* `order_assignment_notifications` Send a notification email when an order is assigned to staff for review
* `product_specific_contacts` Allow a different contact email for each product
* `send_statement_emails` Send email notification when statements are created

## Orders

* `export_order_disputes`: Include dispute information on order details report.
* `my_files`: Enable My Files section for users which shows files attached to orders.
* `price_change_reason_required`: Require a note to manually change order price.
* `print_order_detail`: Show link to print Order Detail on manage order.
* `results_file_notifications`: Notify users by email when new files are uploaded.

## Reservations

* `reservations: grace_period`, `reservations: timeout_period`, `occupancies: timeout_period`, `billing: review_period` various grace periods, time periods, and review periods
* `add_accessories_before_reservation_starts`: Allow to add accessories before a reservation starts.
* `auto_end_reservations_on_next_start` Automatically end previous reservations for timer/relay controlled instruments, when another user starts a new reservation.
* `walkup_reservations`: Show quick reservation link on product detail. Quick reservation page is always enabled.

## Products

* `item_initial_order_status_complete`: Allow Items to have the initial order status set to "Complete".
- `disable_relay_synaccess_rev_a`: Disable creation of relays of type Synaccess Rev A.
- `sanger_enabled_service`: Enable sanger options on Services on Facilities which are sanger enabled.
- `show_daily_rate_option`: Enable "Daily Rate" option in Instrument creation form "Pricing Mode" field.
- `well_plate_alternative_csv_format`: Enable alternative format on exported plate data in sanger sequencing engine.

## Other

* `training_requests` Allow users to request training
* `accounts: product_default` `accounts: revenue_account_default` Specify a default Expense account from which fees will be withdrawn; must be open on purchaser's Chart String - one default for products and one for facilities.  Optionally, these can be edited per product.
* `cross_facility_reports` Allow generating cross facility reports (does not work with SES due to attached file size limits)
* `kiosk_view` Kiosk mode - display a list of actionable reservations without logging in (optionally allow acting w/o auth)
* `bypass_kiosk_auth`: Do not require authentication on Kiosk view actions.
* `active_storage` use `ActiveStorage` if `true`, or `Paperclip` if `false`
* `active_storage_for_images_only` enables `ActiveStorage` for the `DownloadableFiles::Image` module. This flag needs to be enabled even if `active_storage` is
* `show_estimates_option`: Enable estimates menu entry on facility management.
* `billing_log_events`: Enable billing logs on global menu.
* `stored_order_notices`: Show order details notices and problems from order detail table instead of computing them on the fly.
* `admin_skip_order_forms`: Allow admins to skip order forms when ordering for a User. This should be enabled for each Service.
