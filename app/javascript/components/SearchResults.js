import React, { Component } from 'react';
import { exportDefaultDeclaration } from '@babel/types';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faChevronDown } from '@fortawesome/free-solid-svg-icons';
import './collections/Collection.scss';

class SearchResults extends Component {
  constructor(props) {
    super(props);
  }

  duration = ms => {
    if (Number(ms) > 0) return this.millisecondsToFormattedTime(ms);
  };

  millisecondsToFormattedTime = ms => {
    let sec_num = ms / 1000;
    let hours = Math.floor(sec_num / 3600);
    let minutes = Math.floor((sec_num % 3600) / 60);
    let seconds = sec_num - minutes * 60 - hours * 3600;

    let hourStr = hours < 10 ? `0${hours}` : `${hours}`;
    let minStr = minutes < 10 ? `0${minutes}` : `${minutes}`;
    let secStr = seconds.toFixed(0);
    secStr = seconds < 10 ? `0${secStr}` : `${secStr}`;

    return `${hourStr}:${minStr}:${secStr}`;
  };

  displayField = (doc, fieldLabel, fieldName) => {
    if (doc[fieldName]) {
      return (
        <div>
          <span className="field-name">{fieldLabel}</span> {doc[fieldName]}
          <br />
        </div>
      );
    }
  };

  thumbnailSrc = doc => {
    if (doc['section_id_ssim']) {
      return (
        this.props.baseUrl +
        '/master_files/' +
        doc['section_id_ssim'][0] +
        '/thumbnail'
      );
    }
  };

  render() {
    return (
      <ul className="search-within-search-results">
        {this.props.documents.map((doc, index) => {
          return (
            <li key={index} className="row search-within-search-result">
              <div className="document-thumbnail col-sm-3">
                <span className="timestamp badge badge-dark">
                  {this.duration(doc['duration_ssi'])}
                </span>
                <a href={this.props.baseUrl + '/media_objects/' + doc['id']}>
                  {this.thumbnailSrc(doc) && (
                    <img
                      className="card-img-top img-cover"
                      src={this.thumbnailSrc(doc)}
                      alt="Card image cap"
                    />
                  )}
                </a>
              </div>
              <div className="col-sm-9 description">
                <h4>
                  <a href={this.props.baseUrl + '/media_objects/' + doc['id']}>
                    {doc['title_tesi'] || doc['id']}
                  </a>
                </h4>
                <p id={'card-body-' + index} className="card-text">
                  {this.displayField(doc, 'Date', 'date_ssi')}
                  {this.displayField(doc, 'Main Contributors', 'creator_ssim')}
                  {this.displayField(doc, 'Summary', 'summary_ssi')}
                </p>
              </div>
            </li>
          );
        })}
      </ul>
    );
  }
}

export default SearchResults;
