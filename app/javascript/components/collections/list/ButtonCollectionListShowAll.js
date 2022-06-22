/* 
 * Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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
