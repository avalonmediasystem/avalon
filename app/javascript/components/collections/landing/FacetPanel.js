/* 
 * Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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
