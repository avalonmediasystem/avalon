import React from 'react';
import PropTypes from 'prop-types';

const ButtonCollectionListShowAll = ({
  collectionsLength,
  index,
  maxItems,
  handleShowAll,
  showAll
}) => {
  if (collectionsLength > maxItems) {
    return (
      <a
        onClick={handleShowAll}
        className="btn btn-link show-all"
        role="button"
        data-toggle="collapse"
        href={'#collapse' + index}
        aria-expanded={showAll}
        aria-controls={'collapse' + index}
      >
        <i
          className={`fa ${showAll ? 'fa-chevron-down' : 'fa-chevron-right'}`}
        />
        {` Show ${showAll ? `less` : `${collectionsLength} items`}`}
      </a>
    );
  }
  return null;
};

ButtonCollectionListShowAll.propTypes = {
  collectionsLength: PropTypes.number,
  index: PropTypes.number,
  maxItems: PropTypes.number,
  handleShowAll: PropTypes.func,
  showAll: PropTypes.bool
};

export default ButtonCollectionListShowAll;
