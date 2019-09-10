import React, { Component } from 'react';
import { exportDefaultDeclaration } from '@babel/types';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faChevronDown } from '@fortawesome/free-solid-svg-icons'

class SearchResults extends Component {
    constructor(props) {
        super(props);
    }

    duration = (ms) => {
        if (Number(ms) > 0)
            return this.millisecondsToFormattedTime(ms)
    }

    millisecondsToFormattedTime = (ms) => {
        let sec_num = ms / 1000;
        let hours = Math.floor(sec_num / 3600);
        let minutes = Math.floor(sec_num / 60);
        let seconds = sec_num - minutes * 60 - hours * 3600;
    
        let hourStr = hours < 10 ? `0${hours}` : `${hours}`;
        let minStr = minutes < 10 ? `0${minutes}` : `${minutes}`;    
        let secStr = seconds.toFixed(0);
        secStr = seconds < 10 ? `0${secStr}` : `${secStr}`;
    
        return `${hourStr}:${minStr}:${secStr}`;
    }

    displayField = (doc, fieldLabel, fieldName) => {
        if (doc[fieldName]) {
            return <div><span className="field-name">{fieldLabel}</span> {doc[fieldName]}<br/></div>;
        }
    }

    thumbnailSrc = (doc) => {
        if (doc['section_id_ssim']) {
            return this.props.baseUrl + "/master_files/" + doc['section_id_ssim'][0] + "/thumbnail"
        }
    }

    render() {
        return (
        <div className="row">
            {this.props.documents.map((doc,index) => {
                return (
                    <div className="col-lg-4 col-sm-6">
                        <div key={index} className="card mb-2 border-0">
                            <div className="card-img-caption">
                                <p className="timestamp badge badge-dark">{this.duration(doc['duration_ssi'])}</p>
                                <a href={this.props.baseUrl + "/media_objects/" + doc['id']}>
                                    <img className="card-img-top img-cover" src={this.thumbnailSrc(doc)} alt="Card image cap"/>
                                </a>
                            </div>
                            <div className="card-body pl-0 pr-0">
                                <h6 className="card-title">
                                    <div className="row">
                                        <div className="col-10 pr-0">
                                    <a href={this.props.baseUrl + "/media_objects/" + doc['id']}>{doc["title_tesi"]}</a>
                                    </div>
                                    <div className="col-2">
                                    <a href={"#card-body-" + index} data-toggle="collapse" data-target={"#card-body-" + index} role="button" aria-expanded="false" aria-controls={"card-body-" + index}> 
                                      <FontAwesomeIcon icon={faChevronDown} />
                                    </a>
                                    </div>
                                    </div>
                                </h6>
                                <p id={"card-body-" + index} className="card-text collapse">
                                  {this.displayField(doc, 'Date', 'date_ssi')}
                                  {this.displayField(doc, 'Main Contributors', 'creator_ssim')}
                                  {this.displayField(doc, 'Summary', 'summary_ssi')}
                                </p>
                            </div>
                        </div>
                    </div>
                );
            })}
        </div>
        );
    }
  }
  
  export default SearchResults;
  