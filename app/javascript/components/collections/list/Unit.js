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

import { useState } from 'react';
import CollectionCard from './CollectionCard';
import ButtonCollectionListShowAll from './ButtonCollectionListShowAll';
import '../Collection.scss';

const CollectionsListUnit = ({ unitArr, index, sortByAZ, maxItems, showUnitTitle }) => {
  const [showAll, setShowAll] = useState(false);

  let unit = unitArr[0];
  let collections = sortByAZ(unitArr[1]);

  const handleShowAll = () => {
    setShowAll(!showAll);
  };

  return (
    <section className="collection-unit-wrapper">
      {/* Conditionally render unit title: display collection page sorted by units and hide for unit show page */}
      {showUnitTitle && (
        <h2 className="headline collection-list-unit-headline">
          {collections[0]?.unit_url ? <a href={collections[0].unit_url}>{unit}</a> : unit}
        </h2>
      )}

      <div className="row">
        {collections.slice(0, maxItems).map(col => {
          return (
            <div className="col-sm-3" key={col.id}>
              <CollectionCard attributes={col} showUnit={false} />
            </div>
          );
        })}
      </div>

      {showAll && (
        <div className="row" id="collections-list-remaining-collections">
          {collections.slice(maxItems, collections.length).map(col => {
            return (
              <div className="col-sm-3" key={col.id}>
                <CollectionCard attributes={col} showUnit={false} />
              </div>
            );
          })}
        </div>
      )}

      <ButtonCollectionListShowAll
        collectionsLength={collections.length}
        maxItems={maxItems}
        handleShowAll={handleShowAll}
        showAll={showAll}
      />
    </section>
  );
};

export default CollectionsListUnit;
