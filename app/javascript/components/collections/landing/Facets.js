/* 
 * Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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
