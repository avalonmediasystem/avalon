import React, { Component } from 'react';
import { Table, ProgressBar } from 'react-bootstrap';
import axios from 'axios';
import './EncodingDashboard.scss';

import { library, config } from '@fortawesome/fontawesome-svg-core';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faCheckCircle, faTimesCircle } from '@fortawesome/free-solid-svg-icons'
library.add(faCheckCircle, faTimesCircle)

class EncodingDashboard extends Component {
  constructor(props) {
    super(props);
    this.state = {
        encodeJobs: [],
        sort: {
            column: null,
            direction: 'desc'
        }
    }
  }

  componentDidMount() {
      const self = this;
      axios({
          url: this.props.baseUrl
      })
      .then(function(response) {
          self.setState({ encodeJobs: response.data });
          console.log(response);
      })
  }

  renderTableRows() {
      return this.state.encodeJobs.map((job) => {
          const { state, id, progress, title, create_options, created_at } = job;
          const createOptions = JSON.parse(create_options);
          const jobState = state === 'failed' ? <FontAwesomeIcon icon="times-circle"/> : <FontAwesomeIcon icon="check-circle"/>;
          return (
              <tr key={id}>
                  <td>{jobState}</td>
                  <td>{id}</td>
                  <td><ProgressBar now={progress} label={`${progress}%`} /></td>
                  <td className="left-align">{title.split('/').reverse()[0]}</td>
                  <td>{createOptions === null ? '' : createOptions.master_file_id}</td>
                  <td>{''}</td>
                  <td>{created_at}</td>
              </tr>
          )
      })
  }

  setArrow = (column) => {
    let className = 'sort-direction';
    
    if (this.state.sort.column === column) {
      className += this.state.sort.direction === 'asc' ? ' asc' : ' desc';
    }
    return className;
  };

  sortColumn(e, column) {
      const direction = this.state.sort.column ? (this.state.sort.direction === 'asc' ? 'desc' : 'asc') : 'desc';
      const self = this;
      const { encodeJobs } = this.state;
      encodeJobs.sort(function(x, y){
        if(x[column] < y[column]) { return -1; }
        if(x[column] > y[column]) { return 1; }
        return 0;
      });
      if(direction === 'desc') {
          this.state.encodeJobs.reverse();
      }
      self.setState({ encodeJobs, sort: { column, direction} });
  }

  render() {
      console.log(config);
    return (
      <Table striped bordered hover>
        <thead>
            <tr>
                <th onClick={e => this.sortColumn(e, 'state')}>
                    Status
                    <span className={this.setArrow('state')}></span>
                </th>
                <th onClick={e => this.sortColumn(e, 'id')}>
                    ID
                    <span className={this.setArrow('id')}></span>
                </th>
                <th onClick={e => this.sortColumn(e, 'progress')}>
                    Progress
                    <span className={this.setArrow('progress')}></span>
                </th>
                <th onClick={e => this.sortColumn(e, 'title')}>
                    Filename
                    <span className={this.setArrow('title')}></span>
                </th>
                <th onClick={e => this.sortColumn(e, 'master_file_id')}>
                    MasterFile
                    <span className={this.setArrow('master_file_id')}></span>
                </th>
                <th onClick={e => this.sortColumn(e, 'state')}>
                    MediaObject
                    <span className={this.setArrow('state')}></span>
                </th>
                <th onClick={e => this.sortColumn(e, 'created_at')}>
                    Job Started
                    <span className={this.setArrow('created_at')}></span>
                </th>
            </tr>
        </thead>
        <tbody>
            {this.renderTableRows()}
        </tbody>
      </Table>
    );
  }
}

export default EncodingDashboard;