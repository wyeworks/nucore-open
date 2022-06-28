# External Services — Order Forms

Services can require a completed order form which can be hosted through an external service. By default, NUCore uses Form.io as its external service, but it should be simple to integrate another service.

Currently, you can only use one external service class at a time.

## Default (and only): UrlService

You can change the default external service by creating a new class that extends from [`ExternalService`](../app/models/external_service.rb). The current implementation, [`UrlService`](../app/models/url_service.rb), provides the majority of functionality.

There may be other gems or companion applications that utilize `UrlService`.
For example, NU is using `acgt`, `sanger_sequencing`, and the IMSERC application (https://github.com/tablexi/nucore-imserc).

## Process

1. Add the URL to the product under Products > Services > Order Forms and activate the form. This should be the URL for taking a new survey

    For Form.io, this link can be found by logging into Form.io and selecting the "Embed" tab for the form you wish to use.
    The link will look like this: `https://[form-io-stage-path].form.io/[survey-path]`

2. User adds the service to their cart
   
   ![Screenshot](images/complete-online-order-form.png)
   
3. The "Complete Online Order Form" button links (via GET) to the URL added to the product. It also includes the following parameters:

   `success_url` The URL that the external service should redirect to upon completion of the survey.
    e.g. `http://[yourdomain.com]/facilities/[facility_url]/services/[service_url]/surveys/[external_service_id]/complete?receiver_id=[order_detail_id]`

   `receiver_id` The OrderDetail ID

 Other data is also sent along in the query string: order number, quantity, order date, ordering user name/email/NetID,  payment account owner name/email/NetID, and the payment account number.   See `UrlService#additional_query_params` and `SubmissionsController#prefill_data` for a current list of data passed along to the external service.

4. Once the user completes the survey, the external service should redirect the user to `success_url`. The URL should have the following additional parameters:

   `receiver_id` Was passed to the external service
   
   `survey_url` This is the URL to view the completed survey.

5. The user may go and edit their order form
    
    ![Screenshot](images/edit-online-order-form.png)
    
    The link to this will be the `survey_url` passed back unless you have overridden `edit_url` in a subclass of `UrlService`.

6. Once the user has purchased the product, administrators will see a link to "View Order Form" under the order. This links to the `survey_url` that was passed back. 

## Form.io

Form.io is used as a survey tool/data aggregator for service requests associated with an order.
Form data may include pathology sample information, machine shop project schematics, chemical formulae and requested experiment details, and other related non-financial service workflow information. Facility staff can view the forms to see what what is requested or required for the order.

See https://pm.tablexi.com/issues/157154#note-7 for a list of facilities at NU that use form.io surveys.

## Updating OrderDetail records on submission to Form.io

A form.io survey can be configured to update the note, quantity, or reference ID in NUCore upon submission.
On successful survey submission (new or update), an ajax call is made to update the order detail.

This provides additional context for facility staff, especially when viewing a long list of open orders in the New/In Process queue.
This helps staff effectively manage pending service requests and complete them for billing when the work is done.

Here are the steps to configure the form.io survey:

1. Log in to form.io
1. Select the "Live" tab (form.io allows multiple stages for keeping forms organized)
1. Select "Forms" on the side nav bar
1. Click the form you want to edit
1. Create a new form component (or click the gear icon to edit one)
1. Click "API" tab on the top nav
1. In the field for "Property Name", enter "orderDetailQuantity", "orderDetailNote", or "orderDetailReferenceId"
1. Save the changes

### Validating form inputs from Form.io

1. Log in to form.io
1. Select the "Live" tab (form.io allows multiple stages for keeping forms organized)
1. Select "Forms" on the side nav bar
1. Click the form you want to edit
1. Create a new form component (or click the gear icon to edit one)
1. Click "Validation" tab on the top nav
1. Enter a max value in the field for "Maximum Length".  The max for note is 1000 characters, 255 for reference ID.  Use something sensible for quantity.
1. Save the changes

## Testing

You will need a form.io account with access to the NU forms in order to debug or make changes on the form.io side.

There is a product on NU staging set up for testing: https://nucore-staging.northwestern.edu/facilities/zed_mark_2/services/aaron_form_io

## Developer Notes

Your new service must extend from `ExternalService` and contain the following methods:

`receiver` in this case will be the OrderDetail object.

`new_url(receiver)` Returns the URL for filling out a new survey. This URL should contain the `success_url` parameter for where the external service should return after the user completes the survey. The main part of the URL will likely be the `location` field from the database.

`edit_url(receiver)` Returns the URL for editing a completed survey

`show_url(receiver)` Used on the administrative side to link to viewing a completed survey

The easiest way to set up an external service is to extend the `UrlService` class, which contains basic functionality for these three methods.
