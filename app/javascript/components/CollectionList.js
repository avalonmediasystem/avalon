import React, { Component } from 'react';
import Axios from 'axios';

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

    componentDidUpdate(prevProps, prevState) {
        if (prevState.query != this.state.query) {
            this.retrieveResults();
        }
    }

    retrieveResults() {
        let component = this;
        let url = "http://localhost:3000/collections.json";
        console.log("Performing search: " + url);
        Axios({url: url})
            .then(function(response){
                console.log(response);
                component.setState({searchResult: response})
            });
    }
    
    render() {
        const { query } = this.state;
        return (
        <div>
            <form className="container">
                <label htmlFor="q" className="sr-only">search for</label>
                <div className="input-group">
                    <input value={query} onChange={this.handleQueryChange} name="q" className="form-control" placeholder="Search..." autoFocus="autofocus"></input>
                </div>
            </form>
            <div className="row">
                {/* { this.state.searchResult.length } */}
            </div>
        </div>
        );
    }
  }
  
  export default CollectionList;
  