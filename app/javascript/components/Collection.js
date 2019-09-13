import React, { Component } from 'react';

class Collection extends Component {
    constructor(props) {
        super(props);
    }

    render() {
        return (
        <li className="media">
        <div className="media-left">
            {
                this.props.attributes.poster_url && (
                    <div className="document-thumbnail"><img src={this.props.attributes.poster_url} alt="Collection thumbnail"></img></div>
                )
            }
        </div>
        <div className="media-body">
            <h4 className="media-heading"><a href={this.props.attributes.collection_url}>{this.props.attributes.name}</a></h4>
            <dl>
            <dt>Unit</dt>
            <dd>{this.props.attributes.unit}</dd>
            {
                this.props.attributes.description && (
                    <div>
                        <dt>Description</dt>
                        <dd>{this.props.attributes.description}></dd>
                    </div>
                )
            }
            </dl>
        </div>
        </li>
        );
    }
}

export default Collection;