  window.DynamicFields = {

    initialize: function() {
      /* Any fields marked with the class 'dynamic_field' will have an add button appended
       * to the DOM after the label */	
      this.add_button_to_controls();

      $(document).on('click', '.add-dynamic-field', function(event){
        /* When we click the add button we need to manipulate the parent container, which
	 * is a <div class="controls dynamic"> wrapper */
	/* CSS selectors are faster than doing a last() call in jQuery */
        var input_template = $(this).parent().find('input:last');
	/* By doing this we should just keep pushing the add button down as the last
	 * element of the parent container */
	var new_input = $(input_template).clone().attr('value', '');
        $(input_template).after(new_input);
      });
    },

    /* Simpler is better */
    add_button_to_controls: function() {
      var controls = $('.controls.dynamic').append(DynamicFields.add_input_html);
    },

    add_input_html: '<span class="add-dynamic-field"><i class="icon-plus"></i></span>'
  }
