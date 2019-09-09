import React, { Component } from 'react';

class Pagination extends Component {
    constructor(props) {
        super(props);
    }

    handleClick = (page, event) => {
        event.preventDefault();
        this.props.search.setState({ currentPage: page });
    }

    pageStart = (pages) => {
        return pages.offset_value + 1;
    }

    pageEnd = (pages) => {
        return Math.min(pages.offset_value + pages.limit_value, pages.total_count);
    }


    render() {
        if (this.props.pages.total_count) {
            return (
                <div className="sort-pagination mb-3 pull-right">
                    {this.props.pages.prev_page != null ? 
                        (<a href="#" onClick={event => this.handleClick(this.props.pages.prev_page, event)}>Previous</a>)
                    :
                        (<span>Previous</span>)
                    }
                    <span> | {this.pageStart(this.props.pages)}-{this.pageEnd(this.props.pages)} of {this.props.pages.total_count} | </span>
                    {this.props.pages.next_page != null ? 
                        (<a href="#" onClick={event => this.handleClick(this.props.pages.next_page, event)}>Next</a>)
                    :
                        (<span>Next</span>)
                    }
                </div>
            );
        } else if (this.props.pages.total_count === 0) {
            return <p>No results matched your search.</p>
        } else {
            return(
                <div></div>
            );
        }
    }
  }
  
  export default Pagination;
  