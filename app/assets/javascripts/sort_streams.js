$('.sortable').sortable({ 
  disabled: false,
  update: function(e, ui) {
    $('form > [name="masterfile_ids[]"]').remove();

    $(this).find('tr').each(function(){     
      $('<input>').attr({ 
        type: 'hidden', 
        name: 'masterfile_ids[]', 
        value: $(this).data('segment')
      }).appendTo('form');
    });

  }
}).disableSelection().css('cursor', 'move');

$(".sortable").nestedSortable({
  forcePlaceholderSize:true,
  handle: 'div',
  helper: 'clone',
  listType: 'tbody',
  items: 'tr',
  opacity: .6,
  revert: 250,
  tabSize: 25,
  tolerance: 'pointer',
  toleranceElement: '> div'
}).disableSelection();
