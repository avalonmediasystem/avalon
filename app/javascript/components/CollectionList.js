import React, { Component } from 'react';
import Axios from 'axios';
import Collection from './Collection';
import './CollectionList.scss';

class CollectionList extends Component {
  constructor(props) {
    super(props);
    this.state = {
      filter: "",
      searchResult: [],
      filteredResult: [],
      maxItems: 2,
      sort: 'unit'
    };
    if (this.props.filter) {
      this.state.filter = this.props.filter;
    }
  }

  componentDidMount() {
    this.retrieveResults();
  }

  componentDidUpdate(prevProps, prevState) {
    if (prevState.filter != this.state.filter) {
      this.setState({ filteredResult: this.filterCollections(this.state.filter, this.state.searchResult) });
    }
  }

  retrieveResults() {
    let component = this;
    let url = this.props.baseUrl;
    console.log("Performing search: " + url);
    Axios({ url: url })
      .then(function (response) {
        console.log(response);
        component.setState({ searchResult: response.data, filteredResult: component.filterCollections(component.state.filter, response.data) })
      });
  }

  groupByUnit(list) {
    const map = new Map();
    list.forEach((item) => {
      const collection = map.get(item.unit);
      if (!collection) {
        map.set(item.unit, [item]);
      } else {
        collection.push(item);
      }
    });
    let groups = Array.from(map);
    groups.sort((g1,g2) => {
      if (g1[0] < g2[0]) {
        return -1;
      }
      if (g1[0] > g2[0]) {
        return 1;
      }
      return 0;
    });
    return groups;
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
    collections.forEach((col) => {
      if(col.name.toLowerCase().includes(downcaseFilter) || col.unit.toLowerCase().includes(downcaseFilter) || (col.description && col.description.toLowerCase().includes(downcaseFilter))) {
        filteredArray.push(col);
      }
    });
    return filteredArray;
  }

  handleFilterChange = event => {
    this.setState({ filter: event.target.value });
  }

  handleSortChange = event => {
    let val = event.target.querySelector("input").value;
    this.setState({ sort: val });
  }

  handleShowAll = event => {
    if (event.target.text === "Show all") {
      event.target.text = "Show less";
    } else {
      event.target.text = "Show all"
    }
  }

  render() {
    const { query } = this.state;
    return (
      <div className="collection-list-component">
        <div className="stickyUtils mb-3">
          <form className="collection-filter-bar">
            <label htmlFor="q" className="sr-only">search for</label>
            <div className="input-group collection-filter">
              <input value={this.state.filter} onChange={this.handleFilterChange} name="q" className="form-control" placeholder="Filter..." autoFocus="autofocus"></input>
            </div>
          </form>
          <div className="pull-right">
            <span>View by </span>
            <div className="btn-group" data-toggle="buttons">
              <label className={"btn btn-primary sort-btn" + (this.state.sort === "unit" ? " active" : "")} onClick={this.handleSortChange}>
                <input type="radio" value="unit" /> Unit
                </label>
              <label className={"btn btn-primary sort-btn" + (this.state.sort === "az" ? " active" : "")}  onClick={this.handleSortChange}>
                <input type="radio" value="az" /> A-Z
              </label>
            </div>
          </div>
        </div>
        <div className="collection-list">
          {this.state.sort == 'az' ?
            (
              <ul className="mt-3">
                {this.sortByAZ(this.state.filteredResult).map((col, index) => {
                  return (
                    <Collection key={index} attributes={col} showUnit={true}></Collection>
                  );
                })
                }
              </ul>
            )
            :
            (
              this.groupByUnit(this.state.filteredResult).map((unitArr, index) => {
                let unit = unitArr[0];
                let collections = this.sortByAZ(unitArr[1]);
                return (
                  <div>
                    <h3 className="page-header">{unit}</h3>
                      <ul className="">
                        {collections.slice(0, this.state.maxItems).map((col, index) => {
                          return (
                            <Collection key={index} attributes={col} showUnit={false}></Collection>
                          );
                        })}
                        <div className="collapse" id={"collapse" + index}>
                          {collections.slice(this.state.maxItems, collections.length).map((col, index) => {
                            return (
                              <Collection key={index} attributes={col} showUnit={false}></Collection>
                            );
                          })}
                        </div>
                        { collections.length > this.state.maxItems && (
                          <a onClick={this.handleShowAll} className="btn btn-default show-all" role="button" data-toggle="collapse" href={"#collapse" + index} aria-expanded="false" aria-controls={"collapse" + index}>
                            Show all
                          </a>
                        )}
                      </ul>
                  </div>
                );
              })
            )
          }
        </div>
      </div>
    );
  }
}

export default CollectionList;
