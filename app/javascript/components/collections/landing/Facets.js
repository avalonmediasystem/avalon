import React from 'react';
import FacetPanel from './FacetPanel';
import '../Collection.scss';

function Facets(props) {
  const { appliedFacets, facets, docsLength } = props;
  const handleClick = (facetField, facetLabel, item, event) => {
    event.preventDefault();
    let newAppliedFacets = appliedFacets.concat([
      { facetField: facetField, facetLabel: facetLabel, facetValue: item.value }
    ]);
    props.changeFacets(newAppliedFacets, 1);
  };

  const isFacetApplied = (facet, item) => {
    let index = appliedFacets.findIndex(appliedFacet => {
      return (appliedFacet.facetField === facet.name && appliedFacet.facetValue === item.value);
    });
    return index != -1;
  };

  return docsLength > 0 ? (
    <div className="inline">
      <button href="#search-within-facets" data-toggle="collapse" role="button" aria-expanded="false" aria-controls="object_tree" className="btn btn-primary search-within-facets-btn">
        Toggle Filters
      </button>
      <div id="search-within-facets" className="search-within-facets collapse">
        <FacetPanel facets={facets} isFacetApplied={isFacetApplied} handleClick={handleClick}></FacetPanel>
      </div>
    </div>
  ) : ( <div></div> );
}

export default Facets;