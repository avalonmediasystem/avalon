import React, { Component } from 'react';
import './collections/Collection.scss';

class Collection extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <li className="row collection">
        <div className="document-thumbnail col-sm-3">
          {this.props.attributes.poster_url && (
            <a href={this.props.attributes.url}>
              <img
                src={this.props.attributes.poster_url}
                alt="Collection thumbnail"
              ></img>
            </a>
          )}
        </div>
        <div className="col-sm-9 description">
          <h4>
            <a href={this.props.attributes.url}>{this.props.attributes.name}</a>
          </h4>
          <dl>
            {this.props.showUnit && <dt>Unit</dt> && (
              <dd>{this.props.attributes.unit}</dd>
            )}
            {this.props.attributes.description && (
              <div>
                <dd>
                  {this.props.attributes.description.substring(0, 400)}
                  {this.props.attributes.description.length >= 400 && (
                    <span>...</span>
                  )}
                </dd>
              </div>
            )}
          </dl>
        </div>
      </li>
    );
  }
}

export default Collection;
