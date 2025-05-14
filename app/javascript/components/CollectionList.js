/* 
 * Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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

import React, { useEffect, useState } from 'react';
import Axios from 'axios';
import './collections/Collection.scss';
import CollectionListStickyUtils from './collections/list/CollectionListStickyUtils';
import CollectionsSortedByUnit from './collections/list/CollectionsSortedByUnit';
import CollectionsSortedByAZ from './collections/list/CollectionsSortedByAZ';
import CollectionsFilterNoResults from './collections/CollectionsFilterNoResults';
import PropTypes from 'prop-types';
import LoadingSpinner from './ui/LoadingSpinner';

const CollectionList = ({ baseUrl, filter }) => {
  const [collectionFilter, setCollectionFilter] = useState(filter ? filter : '');
  const [searchResult, setSearchResult] = useState([]);
  const [filteredResult, setFilteredResult] = useState([]);
  const [maxItems] = useState(4);
  const [sort, setSort] = useState('unit');
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    const retrieveResults = async () => {
      setIsLoading(true);
      try {
        const response = await Axios({ url: baseUrl });
        const results = response.data;
        setSearchResult(results);
        setFilteredResult(filterCollections(collectionFilter, results));
        setIsLoading(false);
      } catch (error) {
        console.log('Error in retrieveResults(): ', error);
        setIsLoading(false);
      }
    };

    retrieveResults();
  }, [baseUrl]);

  const sortByAZ = (list) => {
    let sortedArray = list.slice();
    sortedArray.sort((col1, col2) => {
      if (col1.name < col2.name) {
        return -1;
      }
      if (col1.name > col2.name) {
        return 1;
      }
      return 0;
    });
    return sortedArray;
  };

  const filterCollections = (filter, collections) => {
    let filteredArray = [];
    let downcaseFilter = filter.toLowerCase();
    collections.forEach(col => {
      if (
        col.name.toLowerCase().includes(downcaseFilter) ||
        col.unit.toLowerCase().includes(downcaseFilter) ||
        (col.description &&
          col.description.toLowerCase().includes(downcaseFilter))
      ) {
        filteredArray.push(col);
      }
    });
    return filteredArray;
  };

  const handleFilterChange = (event) => {
    setCollectionFilter(event.target.value);
  };

  const handleSortChange = (value) => {
    setSort(value);
  };

  const handleSubmit = (event) => {
    event.preventDefault();
  };

  return (
    <>
      <CollectionListStickyUtils
        filter={collectionFilter}
        handleFilterChange={handleFilterChange}
        sort={sort}
        handleSortChange={handleSortChange}
        handleSubmit={handleSubmit}
      />
      {isLoading && <LoadingSpinner isLoading={isLoading} />}
      {(filteredResult.length === 0 && !isLoading) && <CollectionsFilterNoResults />}

      <div className="collection-list">
        {sort === 'az' ? (
          <CollectionsSortedByAZ
            filteredResult={filteredResult}
            sortByAZ={sortByAZ}
          />
        ) : (
          <CollectionsSortedByUnit
            filteredResult={filteredResult}
            sortByAZ={sortByAZ}
            maxItems={maxItems}
          />
        )}
      </div>
    </>
  );
};

CollectionList.propTypes = {
  baseUrl: PropTypes.string,
  filter: PropTypes.string
};

export default CollectionList;
