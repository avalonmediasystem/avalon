import React, { Component } from 'react';
import Axios from 'axios';
import Collection from './Collection';

class CollectionList extends Component {
    constructor(props) {
        super(props);
        this.state = {
            query: "",
            searchResult: [],
            sort: 'AZ'
            // loaded: false
        };
    }

    componentDidMount() {
        this.retrieveResults();
    }

    // componentDidUpdate(prevProps, prevState) {
    //     if (prevState.loaded != this.state.loaded) {
    //         this.retrieveResults();
    //     }
    // }

    retrieveResults() {
        let component = this;
        let url = "http://localhost:3000/collections.json";
        console.log("Performing search: " + url);
        Axios({url: url})
            .then(function(response){
                console.log(response);
                component.setState({searchResult: response.data})
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
      console.log(map);
      return map;
    }

    filterCollections = event => {

    }
    
    render() {
        const { query } = this.state;
        return (
        <div>
            <form className="container">
                <label htmlFor="q" className="sr-only">search for</label>
                <div className="input-group">
                    <input value={query} onChange={this.filterCollections} name="q" className="form-control" placeholder="Filter..." autoFocus="autofocus"></input>
                </div>
            </form>
            
            <div className="row">
                { this.state.sort != 'AZ' ?
                        (
                            <div>
                                {this.state.searchResult.map((col,index) => {
                                    return (
                                      <Collection key={index} attributes={col}></Collection>
                                    );
                                })
                                }
                            </div>
                        )
                    :
                        (
                            <div>
                                {this.groupByUnit(this.state.searchResult).forEach((collections, unit, map) => {
                                  return (
                                    <div>
                                        console.log(unit);
                                        <p>Unit: {unit}</p>

                                        {/* {collections.map((col,index) => {
                                            return (
                                                <Collection key={index} attributes={col}></Collection>
                                            );
                                        })} */}
                                    </div>
                                  );
                                })}
                            </div>
                        )
                }
            </div>
        </div>
        );
    }
  }
  
  export default CollectionList;
  