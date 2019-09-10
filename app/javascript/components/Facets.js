import React, { Component } from 'react';

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
                <div>
                    { this.props.facets.map((facet,index) => {
                        if (facet.items.length === 0) {
                            return (<div></div>);
                        }
                        return(
                            <div className="card mb-3">
                                <h5 className="card-header collapse-toggle">
                                    <a>{facet.label}</a>
                                </h5>
                                <div className="card-body">
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
            );
        } else {
            return(
                <div></div>
            );
        }
    }
  }
  
  export default Facets;
  