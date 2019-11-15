import React, { Component } from 'react';
import Axios from 'axios';
import './collections/Collection.scss';
import CollectionListStickyUtils from './collections/list/CollectionListStickyUtils';
import CollectionsSortedByUnit from './collections/list/CollectionsSortedByUnit';
import CollectionsSortedByAZ from './collections/list/CollectionsSortedByAZ';
import PropTypes from 'prop-types';

class CollectionList extends Component {
  constructor(props) {
    super(props);
    this.state = {
      filter: props.filter ? props.filter : '',
      searchResult: [],
      filteredResult: [],
      maxItems: 3,
      sort: 'unit'
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
    let url = this.props.baseUrl;

    try {
      const response = await Axios({ url });
      this.setState({
        searchResult: response.data,
        filteredResult: this.filterCollections(this.state.filter, response.data)
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

  handleSortChange = event => {
    let val = event.target.querySelector('input').value;
    this.setState({ sort: val });
  };

  render() {
    const { filter, sort, filteredResult, maxItems } = this.state;
    return (
      <div>
        <CollectionListStickyUtils
          filter={filter}
          handleFilterChange={this.handleFilterChange}
          sort={sort}
          handleSortChange={this.handleSortChange}
        />
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
  filter: PropTypes.bool
};

export default CollectionList;
