import React from 'react';
import PropTypes from 'prop-types';

const CollectionListStickyUtils = ({
  filter,
  handleFilterChange,
  handleSortChange,
  sort
}) => {
  return (
    <section className="row stickyUtils collection-list-sticky-utils">
      <div className="col-sm-6">
        <form>
          <div className="form-group">
            <label htmlFor="q" className="sr-only">
              search for
            </label>
            <input
              value={filter}
              onChange={handleFilterChange}
              name="q"
              className="form-control input-lg"
              placeholder="Filter..."
              autoFocus="autofocus"
            />
          </div>
        </form>
      </div>
      <div className="col-sm-6">
        <div className="text-right">
          <span className="collection-list-view-toggle-label">View by:</span>
          <div className="btn-group" data-toggle="buttons">
            <label
              className={
                'btn btn-primary sort-btn' + (sort === 'unit' ? ' active' : '')
              }
              onClick={handleSortChange}
            >
              <input type="radio" value="unit" /> Unit
            </label>
            <label
              className={
                'btn btn-primary sort-btn' + (sort === 'az' ? ' active' : '')
              }
              onClick={handleSortChange}
            >
              <input type="radio" value="az" /> A-Z
            </label>
          </div>
        </div>
      </div>
    </section>
  );
};

CollectionListStickyUtils.propTypes = {
  filter: PropTypes.string,
  handleFilterChange: PropTypes.func,
  handleSortChange: PropTypes.func,
  sort: PropTypes.string
};

export default CollectionListStickyUtils;
