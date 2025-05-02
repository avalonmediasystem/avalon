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
 * Standard debounce function found in libraries like "lodash" or "underscore"
 * @param {Function} fn
 * @param {Number} delay Milliseconds delay
 */
export const debounce = (fn, delay) => {
  let timer = null;
  return function(...args) {
    const context = this;
    timer && clearTimeout(timer);
    timer = setTimeout(() => {
      fn.apply(context, args);
    }, delay);
  };
};

/**
 * Not really sure what this is supposed to do, but something with prepping facets for the Collections Landing page Search component.
 * @param {Array} facets - this is what was passed in from javascript/components/Search.js: "this.state.searchResult.facets"
 * @param {*} collection this is what was passed in from javascript/components/Search.js: "this.props.collection"
 */
export function availableFacets(facets, collection) {
  // TODO: I'd refactor this logic if the code becomes active in the future...
  let theFacets = facets.slice(); // Not sure why the .slice() method is called here
  let facetIndex = theFacets.findIndex(facet => {
    return facet.label === 'Published';
  });
  if (facetIndex > -1) {
    theFacets.splice(facetIndex, 1);
  }
  facetIndex = theFacets.findIndex(facet => {
    return facet.label === 'Created by';
  });
  if (facetIndex > -1) {
    theFacets.splice(facetIndex, 1);
  }
  facetIndex = theFacets.findIndex(facet => {
    return facet.label === 'Date Digitized';
  });
  if (facetIndex > -1) {
    theFacets.splice(facetIndex, 1);
  }
  facetIndex = theFacets.findIndex(facet => {
    return facet.label === 'Date Ingested';
  });
  if (facetIndex > -1) {
    theFacets.splice(facetIndex, 1);
  }

  if (collection) {
    facetIndex = theFacets.findIndex(facet => {
      return facet.label === 'Collection';
    });
    theFacets.splice(facetIndex, 1);
    facetIndex = theFacets.findIndex(facet => {
      return facet.label === 'Unit';
    });
    theFacets.splice(facetIndex, 1);
  }
  return theFacets;
}
