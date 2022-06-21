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

import React, { Component } from 'react';
import Axios from 'axios';
import './collections/Collection.scss';
import CollectionListStickyUtils from './collections/list/CollectionListStickyUtils';
import CollectionsSortedByUnit from './collections/list/CollectionsSortedByUnit';
import CollectionsSortedByAZ from './collections/list/CollectionsSortedByAZ';
import CollectionsFilterNoResults from './collections/CollectionsFilterNoResults';
import PropTypes from 'prop-types';
import LoadingSpinner from './ui/LoadingSpinner';

class CollectionList extends Component {
  constructor(props) {
    super(props);
    this.state = {
      filter: props.filter ? props.filter : '',
      searchResult: [],
      filteredResult: [],
      maxItems: 4,
      sort: 'unit',
      isLoading: false
    };
  }

  componentDidMount() {
    this.retrieveResults();
  }

  componentDidUpdate(prevProps, prevState) {
    if (prevState.filter != this.state.filter) {
      this.setState({
        filteredResult: this.filterCollections(
          this.state.filter,
          this.state.searchResult
        )
      });
    }
  }

  async retrieveResults() {
    this.setState({ isLoading: true });
    let url = this.props.baseUrl;

    try {
      const response = await Axios({ url });
      this.setState({
        searchResult: response.data,
        filteredResult: this.filterCollections(this.state.filter, response.data),
        isLoading: false
      });
    } catch (error) {
      console.log('Error in retrieveResults(): ', error);
      Promise.resolve([]);
    }
  }

  sortByAZ(list) {
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
  }

  filterCollections(filter, collections) {
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
  }

  handleFilterChange = event => {
    this.setState({ filter: event.target.value });
  };

  handleSortChange = value => {
    this.setState({ sort: value });
  };

  handleSubmit = event => {
    event.preventDefault();
  }

  render() {
    const { filter, sort, filteredResult = [], maxItems, isLoading } = this.state;

    return (
      <div>
        <CollectionListStickyUtils
          filter={filter}
          handleFilterChange={this.handleFilterChange}
          sort={sort}
          handleSortChange={this.handleSortChange}
	  handleSubmit={this.handleSubmit}
        />
        {isLoading && <LoadingSpinner isLoading={isLoading} />}
        {(filteredResult.length === 0 && !isLoading) && <CollectionsFilterNoResults />}

        <div className="collection-list">
          {sort === 'az' ? (
            <CollectionsSortedByAZ
              filteredResult={filteredResult}
              sortByAZ={this.sortByAZ}
            />
          ) : (
            <CollectionsSortedByUnit
              filteredResult={filteredResult}
              sortByAZ={this.sortByAZ}
              maxItems={maxItems}
            />
          )}
        </div>
      </div>
    );
  }
}

CollectionList.propTypes = {
  baseUrl: PropTypes.string,
  filter: PropTypes.string
};

export default CollectionList;
