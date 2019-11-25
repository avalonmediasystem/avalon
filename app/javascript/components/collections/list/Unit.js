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
            <div className="col-sm-4" key={col.id}>
              <CollectionCard attributes={col} showUnit={false} />
            </div>
          );
        })}
      </div>

      {showAll && (
        <div className="row" id="collections-list-remaining-collections">
          {collections.slice(maxItems, collections.length).map(col => {
            return (
              <div className="col-sm-4" key={col.id}>
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
