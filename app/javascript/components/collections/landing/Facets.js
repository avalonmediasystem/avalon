import React from 'react';
import PropTypes from 'prop-types';
import { makeStyles } from '@material-ui/core/styles';

import '../Collection.scss';

function Facets(props) {
  const handleClick = (facetField, facetLabel, item, event) => {
    event.preventDefault();
    let newAppliedFacets = props.appliedFacets.concat([
      { facetField: facetField, facetLabel: facetLabel, facetValue: item.value }
    ]);
    props.changeFacets(newAppliedFacets, 1);
  };

  const isFacetApplied = (facet, item) => {
    let index = props.appliedFacets.findIndex(appliedFacet => {
      return (
        appliedFacet.facetField === facet.name && appliedFacet.facetValue === item.value
      );
    });
    return index != -1;
  };

  return props.docsLength > 0 ? (
    <div className="inline">
      <button href="#search-within-facets" data-toggle="collapse" role="button" aria-expanded="false" aria-controls="object_tree" className="btn btn-primary search-within-facets-btn">
        Toggle Filters
      </button>
      <div id="search-within-facets" className="search-within-facets collapse">
        <FiltersPanel facets={props.facets} isFacetApplied={isFacetApplied} handleClick={handleClick}></FiltersPanel>
      </div>
    </div>
  ) : ( <div></div> );
}

export default Facets;

const useStyles = makeStyles(theme => ({
  root: {
    width: '100%'
  },
  panelFlex: {
    [theme.breakpoints.down('sm')]: {
      display: 'block'
    },
    [theme.breakpoints.up('md')]: {
      display: 'flex',
      flexWrap: 'wrap'
    },
    [theme.breakpoints.up('lg')]: {
      display: 'flex'
    }
  },
  facetItem: {
    marginRight: '30px',
    flex: '0 1 30%'
  },
  facetValue: {
    [theme.breakpoints.down('sm')]: {
      paddingLeft: '15px'
    }
  }
}));

function FiltersPanel(props) {
  const classes = useStyles();
  const { facets, isFacetApplied, handleClick } = props;

  return (
    <div className={classes.panelFlex}>
      {facets.map((facet, index) => {
        if (facet.items.length === 0) { return <div key={facet.name}></div> }
        return (
          <div className={classes.facetItem} key={facet.name}>
            <h5 className="page-header upper">{facet.label}</h5>
            <div className="">
              <ul className="facet-values list-unstyled">
                {facet.items.map((item, index) => {
                  return (
                    <li key={item.label}>{isFacetApplied(facet, item) 
                      ? ( <span className="facet-label">{item.label}</span> )
                      : ( <a href="" onClick={event => handleClick(facet.name, facet.label, item, event) } className={classes.facetValue}>
                            <span className="facet-label">{item.label}</span> </a> )}
                      <span className="facet-count"> ({item.hits})</span></li> );
                })}</ul>
            </div>
          </div> ); 
      })}
    </div>
  );
}

FiltersPanel.propTypes = {
  classes: PropTypes.object,
  facets: PropTypes.array.isRequired,
  isFacetApplied: PropTypes.func.isRequired,
  handleClick: PropTypes.func.isRequired
};
