  window.DynamicFields = {
    initialize: function() {
      /* Any fields marked with the class 'dynamic_field' will have an add button appended
       * to the DOM after the label */	
      this.add_remove_buttons_to_dynamic_fields();

      $(document).on('click', '.add-dynamic-field', function(event){
        event.preventDefault();

        // find all the input controls after the add button
        var fields = $(this).next().find('.controls');
        var inputs = $(fields).find('input');
        var last_input = inputs[inputs.length - 1];

        var incremented_rails_id = DynamicFields.copy_and_increment_rails_collection_id( $(last_input).attr('id') );

        $(fields).append( 
          $(last_input).clone().
            attr('id', incremented_rails_id ).
            attr('value','').
            after(DynamicFields.remove_button_html)
        );
      });

      $(document).on('click', '.remove-dynamic-field', function(event){
        event.preventDefault();

	/*
	 * For efficiency's sake cache $(this) instead of making repeated calls against
	 * the DOM
	 */
	node = $(this)
        input_fields_in_control_group = node.parent('.controls').find('input');
        // only remove the input field if there is another input field in the list      
        if (input_fields_in_control_group.length > 1) {
          //remove input field
          node.prev().remove();
          //remove remove icon
          node.remove();
        }

	/*
	 * If there is only one item then hide the controls since you can't actually
	 * click the button in that case */
       if (1 == input_fields_in_control_group.length) {
         node.hide();
       }
      });
    },

    add_remove_buttons_to_dynamic_fields: function(){
      $('.dynamic_field').after(this.remove_button_html);
    },

    copy_and_increment_rails_collection_id: function( current_id ) {
      var match = current_id.match(/([a-z_]+)([0-9]+)/)
      var string_portion_of_id = match[1];
      var integer_portion_of_id = parseInt(match[2]);
      return string_portion_of_id + String(integer_portion_of_id + 1);
    },

    remove_button_html: '<a href="#" class="remove-dynamic-field"><i class="icon-remove-sign"></i></a>'

  }
