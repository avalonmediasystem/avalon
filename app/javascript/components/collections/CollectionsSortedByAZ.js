import React from 'react';
import CollectionCard from './CollectionCard';
import PropTypes from 'prop-types';

const CollectionsSortedByAZ = ({ sortByAZ, filteredResult }) => {
  return (
    <ul className="row list-unstyled">
      {sortByAZ(filteredResult).map(col => {
        return (
          <li className="col-sm-4" key={col.id}>
            <CollectionCard attributes={col} showUnit={true} />
          </li>
        );
      })}
    </ul>
  );
};

CollectionsSortedByAZ.propTypes = {
  sortByAZ: PropTypes.func,
  filteredResult: PropTypes.array
};

export default CollectionsSortedByAZ;
