import React, { Component } from 'react';
import Axios from 'axios';
import SearchResults from './SearchResults';
import Pagination from './Pagination';
import Facets from './Facets';
import FacetBadges from './FacetBadges';
import "./react-blacklight.css";

class Search extends Component {
    constructor(props) {
        super(props);
        this.state = {
            query: "",
            searchResult: {pages:{}, docs:[], facets:[]},
            currentPage: 1,
            appliedFacets: [],
            perPage: 12
        };
    }

    handleQueryChange = event => {
        this.setState({query: event.target.value, currentPage: 1});
    }

    componentDidMount() {
        this.retrieveResults();
    }

    componentDidUpdate(prevProps, prevState) {
        if (prevState.query != this.state.query || prevState.currentPage != this.state.currentPage || prevState.appliedFacets != this.state.appliedFacets) {
            this.retrieveResults();
        }
    }

    retrieveResults() {
        let component = this;
        let facetFilters = "";
        this.state.appliedFacets.forEach((facet) => { facetFilters = facetFilters + "&f[" + facet.facetField + "][]=" + facet.facetValue });
        if (this.props.collection) {
            facetFilters = facetFilters + "&f[collection_ssim][]=" + this.props.collection;
        }
        let url = this.props.baseUrl + "/catalog.json?per_page=" + this.state.perPage + "&q=" + this.state.query + "&page=" + this.state.currentPage + facetFilters;
        console.log("Performing search: " + url);
        Axios({url: url})
            .then(function(response){
                console.log(response);
                component.setState({searchResult: response.data.response})
            });
    }

    availableFacets() {
        let availableFacets = this.state.searchResult.facets.slice();
        let facetIndex = availableFacets.findIndex((facet) => { return facet.label === "Published" });
        if (facetIndex > -1) {
            availableFacets.splice(facetIndex, 1);
        }
        facetIndex = availableFacets.findIndex((facet) => { return facet.label === "Created by" });
        if (facetIndex > -1) {
            availableFacets.splice(facetIndex, 1);
        }
        facetIndex = availableFacets.findIndex((facet) => { return facet.label === "Date Digitized" });
        if (facetIndex > -1) {
            availableFacets.splice(facetIndex, 1);
        }
        facetIndex = availableFacets.findIndex((facet) => { return facet.label === "Date Ingested" });
        if (facetIndex > -1) {
            availableFacets.splice(facetIndex, 1);
        }

        if (this.props.collection) {
            facetIndex = availableFacets.findIndex((facet) => { return facet.label === "Collection" });
            availableFacets.splice(facetIndex, 1);
            facetIndex = availableFacets.findIndex((facet) => { return facet.label === "Unit" });
            availableFacets.splice(facetIndex, 1);

        }
        return availableFacets;
    }
    
    render() {
        const { query } = this.state;
        return (
        <div>
            <form className="container">
                <label htmlFor="q" className="sr-only">search for</label>
                <div className="input-group search-bar">
                    <input value={query} onChange={this.handleQueryChange} name="q" className="form-control" placeholder="Search..." autoFocus="autofocus"></input>
                </div>
            </form>
            <div className="row mb-3">
                <FacetBadges facets={this.state.appliedFacets} search={this}></FacetBadges>
                <Facets facets={this.availableFacets()} search={this}></Facets>
                <Pagination pages={this.state.searchResult.pages} search={this}></Pagination>
            </div>
            <div className="row">
                {/* <section className="col-md-9"> */}
                <SearchResults documents={this.state.searchResult.docs} baseUrl={this.props.baseUrl}></SearchResults>
                {/* </section> */}
            </div>
        </div>
        );
    }
  }
  
  export default Search;
  