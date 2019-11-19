import React from 'react';

function FacetBadges(props) {
  const handleClick = (index, event) => {
    event.preventDefault();
    let newAppliedFacets = props.facets.slice();
    newAppliedFacets.splice(index, 1);
    props.changeFacets(newAppliedFacets);
  };

  return (
    <div className="mb-3 facet-badges">
      { props.facets.map((facet, index) => {
        return (
          <div className="btn-group mr-2" role="group" aria-label="Facet badge" key={facet.facetLabel}>
            <button className="btn btn-default disabled">{facet.facetLabel}: {facet.facetValue}</button>
            <button className="btn btn-default" onClick={event => handleClick(index, event)}>&times;</button>
          </div>
        );
      }) }
    </div>
  );
}

export default FacetBadges;
