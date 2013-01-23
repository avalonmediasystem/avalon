  window.DynamicFields = {

    initialize: function() {
      /* Any fields marked with the class 'dynamic_field' will have an add button appended
       * to the DOM after the label */	
      this.add_controls_to_label();
      this.add_remove_buttons_to_dynamic_fields();

      $(document).on('click', '.add-dynamic-field', function(event){
        // find all the input controls after the add button
        var fields = $(this).parent().find('.controls');
        var inputs = $(fields).find('input');
        var last_input = inputs[inputs.length - 1];

        var incremented_rails_id = DynamicFields.copy_and_increment_rails_collection_id( $(last_input).attr('id') );
        var clone = $(last_input).clone().attr('id', incremented_rails_id ).val('');
        //clone.after(DynamicFields.remove_button_html)
        $(fields).append( clone );
        $(fields).append( DynamicFields.remove_button_html );
        
        if ( inputs.length == 1) {
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
          node.prev().remove();
          node.remove();
        }

      });
    },

    add_controls_to_label: function() {

      var labels = $('input[dynamic="true"]').parent('.controls').parent('.control-group').children('label');

      var that = this;
      labels.each(function(index,label){
        $(label).after(that.add_button_html);
      });

      labels.css('display', 'inline-table');
      labels.css('padding-right','4px');

    },

    add_remove_buttons_to_dynamic_fields: function(){
      $('.controls > input[dynamic="true"]').after(this.remove_button_html);   
    },

    copy_and_increment_rails_collection_id: function( current_id ) {
      var match = current_id.match(/([a-z_]+)([0-9]+)/)
      var string_portion_of_id = match[1];
      var integer_portion_of_id = parseInt(match[2]);
      return string_portion_of_id + String(integer_portion_of_id + 1);
    },

    add_button_html: '<span class="add-dynamic-field"><i class="icon-plus-sign"></i></span>',
    remove_button_html: '<span class="remove-dynamic-field"><i class="icon-remove-sign"></i></span>'

  }
