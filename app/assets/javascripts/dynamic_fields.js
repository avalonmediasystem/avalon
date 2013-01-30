  window.DynamicFields = {

    initialize: function() {
      /* Any fields marked with the class 'dynamic_field' will have an add button appended
       * to the DOM after the label */	
      this.add_controls_to_label();
      this.add_remove_buttons_to_dynamic_fields();

      $(document).on('click', '.add-dynamic-field', function(event){

        // find all the input controls after the add button
        var fields = $(this).parent().parent().find('.controls.dynamic');
        var inputs = $(fields).find('input');
        var input_template = inputs.first()

	/*
	 * Make this simpler - store an attribute on the control container that keeps
	 * track of the index of the last input ID, increment it, and then put it back
	 * in the DOM
	 */
        var incremented_rails_id = parseInt($(fields).data('inputs')) + 1; 
        $(fields).data('inputs', incremented_rails_id);
	var clone = $(input_template).clone().attr('id', incremented_rails_id).val('');

        // add input and remove button
        $(fields).append(clone);
        $(fields).append(DynamicFields.remove_button_html);
        
	// show the first remove dynamic field button
        // because we remove it when there is only one field
        if (inputs.length == 1) {
          $(inputs[0]).next('.remove-dynamic-field').show();
        }

      });

      $(document).on('click', '.remove-dynamic-field', function(event){

      	var node = $(this);
        input_fields_in_control_group = node.parent('.controls').find('input');

        /*
         * If there is only one item then hide the controls since you can't actually
         * click the button in that case. Reshow when there are two or more fields */
        if ( input_fields_in_control_group.length == 2 ) {
          abc = $(this);
         $(this).parent().find('.remove-dynamic-field').hide();
        }
        
        if (input_fields_in_control_group.length > 1 ) {
          //remove the input field
          node.prev().remove();
          //remove the remove button
          node.remove();
        }

      });
    },

    add_controls_to_label: function() {

      var labels = $('.controls.dynamic').parent('.control-group').children('label');

      var that = this;
      labels.each(function(index,label){
        $(label).append(that.add_button_html);
      });
    },

    add_remove_buttons_to_dynamic_fields: function(){
      $('.controls.dynamic > input').after(this.remove_button_html);   
    },

    //makes an attempt at making sure the id's of each input are unique
    copy_and_increment_rails_collection_id: function( current_id ) {
      var match = current_id.match(/([a-z_]+)([0-9]+)/)
      var string_portion_of_id = match[1];
      var integer_portion_of_id = parseInt(match[2]);
      return string_portion_of_id + String(integer_portion_of_id + 1);
    },

    add_button_html: '<span class="add-dynamic-field"><i class="icon-plus-sign"></i></span>',
    remove_button_html: '<span class="remove-dynamic-field"><i class="icon-remove-sign"></i></span>'

  }
