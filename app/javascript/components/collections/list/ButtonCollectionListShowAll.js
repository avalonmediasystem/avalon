import React from 'react';
import PropTypes from 'prop-types';

const ButtonCollectionListShowAll = ({
  collectionsLength,
  maxItems,
  handleShowAll,
  showAll
}) => {
  if (collectionsLength > maxItems) {
    return (
      <button
        aria-controls="collections-list-remaining-collections"
        aria-expanded={showAll}
        onClick={handleShowAll}
        className="btn btn-link show-all"
        role="button"
      >
        <i
          className={`fa ${showAll ? 'fa-chevron-down' : 'fa-chevron-right'}`}
        />
        {` Show ${showAll ? `less` : `${collectionsLength} items`}`}
      </button>
    );
  }
  return null;
};

ButtonCollectionListShowAll.propTypes = {
  collectionsLength: PropTypes.number,
  maxItems: PropTypes.number,
  handleShowAll: PropTypes.func,
  showAll: PropTypes.bool
};

export default ButtonCollectionListShowAll;
