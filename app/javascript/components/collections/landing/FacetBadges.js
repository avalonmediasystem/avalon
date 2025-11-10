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
          <div className="btn-group me-2" role="group" aria-label="Facet badge" key={facet.facetLabel}>
            <button className="btn btn-outline disabled">{facet.facetLabel}: {facet.facetValue}</button>
            <button className="btn btn-outline" onClick={event => handleClick(index, event)}>&times;</button>
          </div>
        );
      }) }
    </div>
  );
}

export default FacetBadges;
