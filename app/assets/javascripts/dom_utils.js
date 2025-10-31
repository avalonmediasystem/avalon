/* 
 * Copyright 2011-2025, The Trustees of Indiana University and Northwestern
 *   University.  Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed
 *   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 *   CONDITIONS OF ANY KIND, either express or implied. See the License for the
 *   specific language governing permissions and limitations under the License.
 * ---  END LICENSE_HEADER BLOCK  ---
*/

/**
 * Short alias for document.getElementById
 * @param {String} id the element ID
 * @returns {HTMLElement|null}
 */
function getById(id) {
  return document.getElementById(id);
}

/**
 * Short alias for document.querySelector
 * @param {String} selector CSS selector
 * @param {Document|Element|HTMLElement} source reference source
 * @returns {Element|null}
 */
function query(selector, source = document) {
  return source.querySelector(selector);
}

/**
 * Short alias for document.querySelectorAll
 * @param {String} selector CSS selector
 * @param {Document|Element|HTMLElement} source reference source
 * @returns {NodeList}
 */
function queryAll(selector, source = document) {
  return source.querySelectorAll(selector);
}

/**
 * Helper function to show/hide collapsible Bootstrap elements
 * @param {Object} element HTML collapsible element
 * @param {Boolean} toShow 
 */
function showOrCollapse(element, toShow) {
  const collapse = bootstrap.Collapse.getOrCreateInstance(element);
  toShow ? collapse.show() : collapse.hide();
}

/**
 * Helper function to show/hide modal Bootstrap elements
 * @param {Object} element HTML modal element
 * @param {Boolean} toShow 
 */
function toggleModal(element, toShow) {
  const modal = bootstrap.Modal.getOrCreateInstance(element);
  toShow ? modal.show() : modal.hide();
}
