import React, { useState } from 'react';
import CollectionCard from './CollectionCard';
import '../Collection.scss';
import ButtonCollectionListShowAll from './ButtonCollectionListShowAll';
import PropTypes from 'prop-types';

const CollectionsSortedByUnit = ({ filteredResult, sortByAZ, maxItems }) => {
  const [showAll, setShowAll] = useState(false);

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

  const handleShowAll = event => {
    setShowAll(!showAll);
  };

  return groupByUnit(filteredResult).map((unitArr, index) => {
    let unit = unitArr[0];
    let collections = sortByAZ(unitArr[1]);

    return (
      <section key={unit} className="collection-unit-wrapper">
        <h2 className="headline collection-list-unit-headline">{unit}</h2>

        <div className="row">
          {collections.slice(0, maxItems).map((col, index) => {
            return (
              <div className="col-sm-4" key={col.id}>
                <CollectionCard attributes={col} showUnit={false} />
              </div>
            );
          })}
        </div>

        <div className="collapse" id={'collapse' + index}>
          <div className="row">
            {collections.slice(maxItems, collections.length).map(col => {
              return (
                <div className="col-sm-4" key={col.id}>
                  <CollectionCard attributes={col} showUnit={false} />
                </div>
              );
            })}
          </div>
        </div>

        <ButtonCollectionListShowAll
          collectionsLength={collections.length}
          maxItems={maxItems}
          handleShowAll={handleShowAll}
          index={index}
          showAll={showAll}
        />
      </section>
    );
  });
};

CollectionsSortedByUnit.propTypes = {
  filteredResult: PropTypes.array,
  sortByAZ: PropTypes.func,
  maxItems: PropTypes.number
};

export default CollectionsSortedByUnit;
