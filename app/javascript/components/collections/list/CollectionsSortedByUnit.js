/* 
 * Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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
import '../Collection.scss';
import PropTypes from 'prop-types';
import CollectionsListUnit from './Unit';

const CollectionsSortedByUnit = ({ filteredResult, sortByAZ, maxItems }) => {
  const groupByUnit = list => {
    const map = new Map();
    list.forEach(item => {
      const collection = map.get(item.unit);
      if (!collection) {
        map.set(item.unit, [item]);
      } else {
        collection.push(item);
      }
    });
    let groups = Array.from(map);
    groups.sort((g1, g2) => {
      if (g1[0] < g2[0]) {
        return -1;
      }
      if (g1[0] > g2[0]) {
        return 1;
      }
      return 0;
    });
    return groups;
  };

  return groupByUnit(filteredResult).map((unitArr, index) => (
    <CollectionsListUnit
      key={unitArr[0]}
      unitArr={unitArr}
      index={index}
      sortByAZ={sortByAZ}
      maxItems={maxItems}
    />
  ));
};

CollectionsSortedByUnit.propTypes = {
  filteredResult: PropTypes.array,
  sortByAZ: PropTypes.func,
  maxItems: PropTypes.number
};

export default CollectionsSortedByUnit;
