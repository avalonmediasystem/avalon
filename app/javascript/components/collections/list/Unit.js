/*
 * Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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

import React, { useState } from 'react';
import CollectionCard from './CollectionCard';
import ButtonCollectionListShowAll from './ButtonCollectionListShowAll';
import '../Collection.scss';

const CollectionsListUnit = ({ unitArr, index, sortByAZ, maxItems }) => {
  const [showAll, setShowAll] = useState(false);

  let unit = unitArr[0];
  let collections = sortByAZ(unitArr[1]);

  const handleShowAll = () => {
    setShowAll(!showAll);
  };

  return (
    <section className="collection-unit-wrapper">
      <h2 className="headline collection-list-unit-headline">{unit}</h2>

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
