$ ->
  $('[data-toggle=tooltip]').tooltip()
 
  # Make sure tooltips get initialzed on modal loading
  $('body').on 'modal:loaded', '.modal', ->
    
    $(this).find('[data-toggle=tooltip]').tooltip()

