# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

$('.tooltip-label')
  .click (event) ->
    event.preventDefault()
    targetNode = $(this).data('tooltip')
    $(targetNode).collapse('toggle')

$('.form-text .close').click (event) ->
  event.preventDefault()
  $(this).parent().collapse('toggle')
