$(document).ready(function() {
  // Only execute if we're on the problem notifications page
  if ($('input[name="notification_groups[]"]').length === 0) {
    return;
  }

  const notificationGroupCheckboxes = $('input[name="notification_groups[]"]');
  const submitButton = $('.js--requireValueForSubmit');
  const orderDetailCheckboxes = $('input[name="order_detail_ids[]"]');
  const form = $('.form-horizontal');

  const originalTemplate = submitButton.data('confirm-template');
  const selectOrderAlert = submitButton.data('select-order-alert');
  const selectGroupAlert = submitButton.data('select-group-alert');
  const notificationCountError = submitButton.data('notification-count-error');
  submitButton.removeAttr('data-confirm');

  function updateSubmitButton() {
    const hasSelectedGroups = notificationGroupCheckboxes.filter(':checked').length > 0;
    const hasSelectedOrders = orderDetailCheckboxes.filter(':checked').length > 0;
    
    submitButton.prop('disabled', !(hasSelectedGroups && hasSelectedOrders));
  }

  function getNotificationCount() {
    const selectedOrderDetails = orderDetailCheckboxes.filter(':checked').map(function() {
      return this.value;
    }).get();
    
    const selectedGroups = notificationGroupCheckboxes.filter(':checked').map(function() {
      return this.value;
    }).get();

    if (selectedOrderDetails.length === 0) {
      return $.Deferred().resolve({ emails: 0, users: 0 }).promise();
    }

    if (selectedGroups.length === 0) {
      return $.Deferred().resolve('no_groups').promise();
    }

    return $.ajax({
      url: form.attr('action').replace('send_problem_notifications', 'notification_count'),
      method: 'GET',
      data: {
        order_detail_ids: selectedOrderDetails,
        notification_groups: selectedGroups
      }
    }).done(function(response) {
      return response;
    }).fail(function(error) {
      return { emails: 0, users: 0 };
    });
  }

  notificationGroupCheckboxes.on('change', function() {
    updateSubmitButton();
  });
  
  orderDetailCheckboxes.on('change', function() {
    updateSubmitButton();
  });

  // Intercept the button click to handle confirmation
  submitButton.on('click', function(e) {
    e.preventDefault();
    
    const selectedOrderDetails = orderDetailCheckboxes.filter(':checked').length;
    const selectedGroups = notificationGroupCheckboxes.filter(':checked').length;
    
    if (selectedOrderDetails === 0) {
      alert(selectOrderAlert);
      return false;
    }
    
    if (selectedGroups === 0) {
      alert(selectGroupAlert);
      return false;
    }
    
    getNotificationCount().done(function(result) {
      let message;
      
      if (result === 'no_groups') {
        alert(selectGroupAlert);
        return false;
      } else {
        message = originalTemplate.replace('{count}', result.emails).replace('{users}', result.users);
      }
      
      if (confirm(message)) {
        const tempForm = $('<form>')
          .attr('method', 'POST')
          .attr('action', form.attr('action'))
          .css('display', 'none');
        
        const csrfToken = $('meta[name="csrf-token"]').attr('content');
        if (csrfToken) {
          $('<input>').attr('type', 'hidden').attr('name', 'authenticity_token').val(csrfToken).appendTo(tempForm);
        }
      
        orderDetailCheckboxes.filter(':checked').each(function() {
          $('<input>').attr('type', 'hidden').attr('name', 'order_detail_ids[]').val(this.value).appendTo(tempForm);
        });
        
        notificationGroupCheckboxes.filter(':checked').each(function() {
          $('<input>').attr('type', 'hidden').attr('name', 'notification_groups[]').val(this.value).appendTo(tempForm);
        });
        
        tempForm.appendTo('body').submit();
      }
    }).fail(function() {
      alert(notificationCountError);
    });
    
    return false;
  });

  updateSubmitButton();
}); 
