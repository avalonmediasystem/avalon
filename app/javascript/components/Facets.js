import React, { Component } from 'react';
import "./react-blacklight.css";

class Facets extends Component {
    constructor(props) {
        super(props);
    }

    handleClick = (facetField, facetLabel, item, event) => {
        event.preventDefault();
        let newAppliedFacets = this.props.search.state.appliedFacets.concat([{facetField: facetField, facetLabel: facetLabel, facetValue: item.value}]);
        console.log(newAppliedFacets);
        this.props.search.setState({appliedFacets: newAppliedFacets, currentPage: 1});
    }

    isFacetApplied = (facet, item) => {
        let index = this.props.search.state.appliedFacets.findIndex((appliedFacet) => { return appliedFacet.facetField === facet.name && appliedFacet.facetValue === item.value });
        return index != -1;
    }

    render() {
        if (this.props.facets != {}) {
            return (
                <div className="inline">
                    <button href="#search-within-facets" data-toggle="collapse" role="button" aria-expanded="false" aria-controls="object_tree" className="btn btn-default mb-3 search-within-facets-btn">Filters</button>
                    <div id="search-within-facets" className="search-within-facets collapse">
                        { this.props.facets.map((facet,index) => {
                            if (facet.items.length === 0) {
                                return (<div></div>);
                            }
                            return(
                                <div className="search-within-facet">
                                    <h5 className="page-header upper">{facet.label}</h5>
                                    <div className="">
                                        <ul className="facet-values list-unstyled">
                                            { facet.items.map((item, index) => {
                                                return(
                                                    <li>
                                                        { this.isFacetApplied(facet, item) ?
                                                                <span className="facet-label">{item.label}</span>
                                                            :
                                                                <a href="" onClick={event => this.handleClick(facet.name, facet.label, item, event)}><span className="facet-label">{item.label}</span></a>
                                                        }
                                                        <span className="facet-count"> ({item.hits})</span>
                                                    </li>
                                                );
                                            })}
                                        </ul>
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                </div>
            );
        } else {
            return(
                <div></div>
            );
        }
    }
  }
  
  export default Facets;
  