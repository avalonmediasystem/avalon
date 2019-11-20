
import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';

const styles = {
  facetItem: {
    marginRight: '30px',
    flex: '0 1 30%'
  },
  panelFlex: isBlock => ({
    display: isBlock ? 'block' : 'flex',
    flexWrap: isBlock ? '' : 'wrap'
  }),
  facetValue: isBlock => ({
    paddingLeft: isBlock ? '15px' : '0px'
  })
};

function FacetPanel(props) {
  const { facets, isFacetApplied, handleClick } = props;
  // Detect browser width, returns a MediaQueryList object
  const mediaMatch = window.matchMedia('(max-width: 767px)');
  const [matches, setMatches] = useState(mediaMatch.matches);

  // Register/unregister a handler on the MediaQueryList object
  useEffect(() => {
    const handler = e => setMatches(e.matches);
    mediaMatch.addListener(handler);
    return () => mediaMatch.removeListener(handler);
  });

  return (<div style={styles.panelFlex(matches)}>
            { facets.map((facet, index) => {
                if (facet.items.length === 0) { return <div key={facet.name}></div> }
                  return (
                    <div style={styles.facetItem} key={facet.name}>
                      <h5 className="page-header upper">{facet.label}</h5>
                      <div style={styles.facetValue(matches)}>
                        <ul className="facet-values list-unstyled">
                          { facet.items.map((item, index) => {
                            return (<li key={item.label}>
                                      { isFacetApplied(facet, item) ? ( <span className="facet-label">{item.label}</span> ) : ( <a href="" onClick={event => handleClick(facet.name, facet.label, item, event) }><span className="facet-label">{item.label}</span></a> )}
                                      <span className="facet-count"> ({item.hits})</span>
                                    </li>); })}
                        </ul>
                      </div>
                    </div>); }) }
          </div> );
}

FacetPanel.propTypes = {
  facets: PropTypes.array.isRequired,
  isFacetApplied: PropTypes.func.isRequired,
  handleClick: PropTypes.func.isRequired
};

export default FacetPanel;
