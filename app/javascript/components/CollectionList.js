import React, { Component } from 'react';
import Axios from 'axios';
import Collection from './Collection';

class CollectionList extends Component {
    constructor(props) {
        super(props);
        this.state = {
            query: "",
            searchResult: []
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
      return Array.from(map);
    }

    sortByAZ(list) {
        let sortedArray = this.state.searchResult.slice();
        sortedArray.sort((col1,col2) => {
            if(col1.name < col2.name){
                return -1;
            }
            if(col1.name > col2.name){
                return 1;
            }
            return 0;
        });
        return sortedArray;
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
                { this.props.sort == 'AZ' ?
                        (
                            <div>
                                {this.sortByAZ(this.state.searchResult).map((col,index) => {
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
                                {this.groupByUnit(this.state.searchResult).map((unitArr, index) => {
                                  let unit = unitArr[0];
                                  let collections = unitArr[1];
                                  return (
                                    <div>
                                        <p>Unit: {unit}</p>

                                        {collections.map((col,index) => {
                                            return (
                                                <Collection key={index} attributes={col}></Collection>
                                            );
                                        })}
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
  