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
import axios from 'axios';
import SearchResults from './collections/landing/SearchResults';
import Pagination from './collections/landing/Pagination';
import { debounce } from '../services';
import LoadingSpinner from '../components/ui/LoadingSpinner';
import PropTypes from 'prop-types';

class Search extends Component {
  constructor(props) {
    super(props);
    this.state = {
      query: '',
      searchResult: { pages: {}, docs: [], facets: [] },
      currentPage: 1,
      appliedFacets: [],
      perPage: 12,
      isLoading: false
    };
    // Put a 1000ms delay on search network requests
    this.delayedRetrieveResults = debounce(this.delayedRetrieveResults, 1000);

    this.filterURL = `${props.baseUrl}?f[collection_ssim][]=${props.collection}`;
  }

  static propTypes = {
    baseUrl: PropTypes.string,
    collection: PropTypes.string
  };

  handleQueryChange = event => {
    this.setState({ query: event.target.value, currentPage: 1 });
  };

  handleSubmit = event => {
    event.preventDefault();
  }

  componentDidMount() {
    this.retrieveResults();
  }

  componentDidUpdate(prevProps, prevState) {
    if (
      prevState.query != this.state.query ||
      prevState.appliedFacets != this.state.appliedFacets
    ) {
      // Handle updates to either search box or facets (facets not currently supported)
      this.delayedRetrieveResults();
    } else if (prevState.currentPage != this.state.currentPage) {
      // Handle pagination update
      this.retrieveResults();
    }
  }

  delayedRetrieveResults() {
    this.retrieveResults();
  }

  /**
   * Handle making an updated search request.
   * Note that "filtering" and "faceting" are not currently built into the Avalon 7.0 release, but may be added in the future...
   */
  async retrieveResults() {
    this.setState({ isLoading: true });
    let { perPage, query, currentPage, appliedFacets } = this.state;
    let url = `${
      this.props.baseUrl
    }/catalog.json?per_page=${perPage}&q=${query}&page=${currentPage}${this.prepFacetFilters(
      appliedFacets
    )}`;

    try {
      let response = null;
      if(this.props.collection) {
        // Pass collection name as a param instead of appending it to the url as a string to
        // accommodate for special characters (&, #, $, etc.) 
        response = await axios.get(url, { params: { 'f[collection_ssim][]': this.props.collection}});
      } else {
        response = await axios.get(url);
      }
      this.setState({
        isLoading: false,
        searchResult: response.data.response
      });
    } catch (e) {
      console.log('Error retrieving results', e);
    }
  }

  changeFacets = (newFacets, currentPage = 1) => {
    this.setState({ appliedFacets: newFacets, currentPage });
  };

  changePage = currentPage => {
    this.setState({ currentPage });
  };

  /**
   * When facets are applied (not currently implemented), prepare facets for usage in a url for network request
   * @param {Array} appliedFacets
   */
  prepFacetFilters(appliedFacets = []) {
    let facetFilters = '';

    appliedFacets.forEach(facet => {
      facetFilters = `${facetFilters}&f[${facet.facetField}][]=${facet.facetValue}`;
    });
    return facetFilters;
  }

  render() {
    const { isLoading, query, searchResult } = this.state;

    return (
      <div className="search-wrapper">
        <div className="row">
          <form onSubmit={this.handleSubmit} className="search-bar col-sm-6 col-sm-offset-3">
            <label htmlFor="q" className="sr-only">
              search for
            </label>
            <input
              value={query}
              onChange={this.handleQueryChange}
              name="q"
              className="form-control input-lg"
              placeholder="Search within collection..."
              autoFocus="autofocus"
            ></input>
          </form>
        </div>
        <div className="collection-landing-pagination-wrapper">
          <Pagination pages={searchResult.pages} changePage={this.changePage} />
        </div>
        <div className="collection-search-results-wrapper">
          <LoadingSpinner isLoading={isLoading} />
          {!isLoading && <SearchResults documents={searchResult.docs} baseUrl={this.props.baseUrl} />}
        </div>
        <div className="collection-landing-pagination-wrapper">
          { searchResult.pages.total_count > searchResult.pages.limit_value && 
              <Pagination pages={searchResult.pages} changePage={this.changePage} />
          }
        </div>
      </div>
    );
  }
}

export default Search;
