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
