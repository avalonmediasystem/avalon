# 
# Disable the default action for tooltips if the Javascript for the
# inline tip is able to work. Since we know that these will have additional
# data attributes there is no need for another class hook
# 
$('.equal-height')
  .addClass('in')
  .height(Math.max.apply(null,($('.equal-height').map (i,elem) -> $(elem).height()).get()))
  .removeClass('in')

$('.tooltip-help')
  .each () ->
    $(this)
      .removeAttr('href')
      .removeAttr('target')
      .append(' <i class="icon-question-sign"/>')
  .click (event) ->
    event.preventDefault()
    targetNode = $(this).data('tooltip')
    $(targetNode).toggleClass('in')

$('.form-tooltip button.close').click (event) ->
  event.preventDefault()
  $(this).parent().toggleClass('in')

# $('.popover-help')
#   .popover
#     placement: 'right',
#     html: true,
#     trigger: 'hover',
#     delay:
#       show: 250,
#       hide: 500
#     content: () ->
#       $(this).parent().next('.form-tooltip').html()
#   .removeAttr('href')
#   .removeAttr('target')
#   .append(' <i class="icon-question-sign" />');
# 
# $('.role-popover-help')
#   .popover
#     placement: 'top',
#     html: true,
#     trigger: 'manual',
#     delay:
#       show: 250,
#       hide: 500
#     content: () ->
#       $(this).closest('p').next('.form-tooltip').html() 
# 
# $('.role-popover-help a')
#   .removeAttr('href')
#   .removeAttr('target')
#   .append(' <i class="icon-question-sign" />')
#   .mouseenter () ->
#     t = $(this).closest('.role-popover-help')
#     t.popover('show')
#     popover = t.next('.popover')
#     if popover.length > 0
#       icon = t.find('i')
#       popover.css('left',icon.offset().left-(30-icon.width()/2))
#   .mouseleave () ->
#     $(this).closest('.role-popover-help').popover('hide')

