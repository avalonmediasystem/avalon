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
