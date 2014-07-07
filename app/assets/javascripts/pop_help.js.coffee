# Copyright 2011-2014, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
# 
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed 
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the 
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

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
