import React, { Component } from 'react';
import Axios from 'axios';
import SearchResults from './collections/landing/SearchResults';
import Pagination from './collections/landing/Pagination';

class Search extends Component {
  constructor(props) {
    super(props);
    this.state = {
      query: '',
      searchResult: { pages: {}, docs: [], facets: [] },
      currentPage: 1,
      appliedFacets: [],
      perPage: 10,
      filterURL: props.baseUrl + '?f[collection_ssim][]=' + props.collection
    };
  }

  handleQueryChange = event => {
    this.setState({ query: event.target.value, currentPage: 1 });
  };

  componentDidMount() {
    this.retrieveResults();
  }

  componentDidUpdate(prevProps, prevState) {
    if (
      prevState.query != this.state.query ||
      prevState.currentPage != this.state.currentPage ||
      prevState.appliedFacets != this.state.appliedFacets
    ) {
      this.retrieveResults();
    }
  }

  retrieveResults() {
    let component = this;
    let facetFilters = '';
    this.state.appliedFacets.forEach(facet => {
      facetFilters =
        facetFilters + '&f[' + facet.facetField + '][]=' + facet.facetValue;
    });
    if (this.props.collection) {
      facetFilters =
        facetFilters + '&f[collection_ssim][]=' + this.props.collection;
    }
    let url =
      this.props.baseUrl +
      '/catalog.json?per_page=' +
      this.state.perPage +
      '&q=' +
      this.state.query +
      '&page=' +
      this.state.currentPage +
      facetFilters;
    console.log('Performing search: ' + url);
    Axios({ url: url }).then(function(response) {
      console.log(response);
      component.setState({ searchResult: response.data.response });
    });
  }

  availableFacets() {
    let availableFacets = this.state.searchResult.facets.slice();
    let facetIndex = availableFacets.findIndex(facet => { return facet.label === 'Published' });
    if (facetIndex > -1) { availableFacets.splice(facetIndex, 1) }
    facetIndex = availableFacets.findIndex(facet => { return facet.label === 'Created by' });
    if (facetIndex > -1) { availableFacets.splice(facetIndex, 1) }
    facetIndex = availableFacets.findIndex(facet => { return facet.label === 'Date Digitized' });
    if (facetIndex > -1) { availableFacets.splice(facetIndex, 1); }
    facetIndex = availableFacets.findIndex(facet => { return facet.label === 'Date Ingested' });
    if (facetIndex > -1) { availableFacets.splice(facetIndex, 1); }

    if (this.props.collection) {
      facetIndex = availableFacets.findIndex(facet => { return facet.label === 'Collection' });
      availableFacets.splice(facetIndex, 1);
      facetIndex = availableFacets.findIndex(facet => { return facet.label === 'Unit' });
      availableFacets.splice(facetIndex, 1);
    }
    return availableFacets;
  }

  changeFacets = (newFacets, currentPage) => {
    this.setState({ appliedFacets: newFacets, currentPage });
  };

  render() {
    const { query, searchResult, filterURL } = this.state;
    return (
      <div className="search-wrapper">
        <div className="row">
          <form className="search-bar col-sm-6">
            <label htmlFor="q" className="sr-only">search for</label>
            <input value={query} onChange={this.handleQueryChange} name="q" className="form-control input-lg" placeholder="Search within collection..." autoFocus="autofocus"></input>
          </form>
          <div className="col-sm-6 text-right">
            <a href={filterURL} className="btn btn-primary pull-right">Filter this collection</a>
          </div>
        </div>
        <div className="row mb-3">
          <Pagination pages={searchResult.pages} search={this}></Pagination>
        </div>
        <div className="row">
          {/* <section className="col-md-9"> */}
          <SearchResults documents={searchResult.docs} baseUrl={this.props.baseUrl}></SearchResults>
          {/* </section> */}
        </div>
      </div>
    );
  }
}

export default Search;
