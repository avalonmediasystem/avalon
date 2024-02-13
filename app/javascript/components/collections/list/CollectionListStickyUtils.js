/* 
 * Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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
import PropTypes from 'prop-types';

const CollectionListStickyUtils = ({
  filter,
  handleFilterChange,
  handleSortChange,
  handleSubmit,
  sort
}) => {
  return (
    <section className="row stickyUtils collection-list-sticky-utils">
      <div className="col-sm-6">
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="q" className="sr-only">
              search for
            </label>
            <input
              value={filter}
              onChange={handleFilterChange}
              name="q"
              className="form-control form-control-lg"
              placeholder="Search collections..."
              autoFocus="autofocus"
            />
          </div>
        </form>
      </div>
      <div className="col-sm-6">
        <div className="text-right">
          <span className="collection-list-view-toggle-label">View by:</span>
          <div className="btn-group btn-group-toggle">
            <label
              className={
                'btn btn-primary sort-btn' + (sort === 'unit' ? ' active' : '')
              }
              onClick={() => handleSortChange('unit')}
            >
              <input type="radio" value="unit" /> Unit
            </label>
            <label
              className={
                'btn btn-primary sort-btn' + (sort === 'az' ? ' active' : '')
              }
              onClick={() => handleSortChange('az')}
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
  handleSubmit: PropTypes.func,
  sort: PropTypes.string
};

export default CollectionListStickyUtils;
