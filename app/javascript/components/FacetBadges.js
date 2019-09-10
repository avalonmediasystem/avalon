import React, { Component } from 'react';

class FacetBadges extends Component {
    constructor(props) {
        super(props);
    }

    handleClick = (index, event) => {
        event.preventDefault();
        console.log(index);
        let newAppliedFacets = this.props.facets.slice();
        console.log(newAppliedFacets);
        newAppliedFacets.splice(index, 1);
        console.log(newAppliedFacets);
        this.props.search.setState({appliedFacets: newAppliedFacets});
    }

    render() {
        if (this.props.facets != []) {
            return (
                <div className="mb-3">
                    { this.props.facets.map((facet,index) => {
                        if (facet.length === 0) {
                            return (<div></div>);
                        }
                        return(
                            <div className="btn-group mr-2" role="group" aria-label="Facet badge">
                                <button class="btn btn-outline-secondary disabled">
                                    {facet.facetLabel}: {facet.facetValue}
                                </button>
                                <button className="btn btn-outline-secondary" onClick={event => this.handleClick(index, event)}>&times;</button>
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
  
  export default FacetBadges;
  