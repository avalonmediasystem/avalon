import React, { Component } from 'react';
import axios from 'axios';
import { BrowserRouter as Router, Route } from 'react-router-dom';
import EncodeJobView from './EncodeJobView';
import EncodeJobTable from './EncodeJobTable';

import './EncodingDashboard.scss';

import { library } from '@fortawesome/fontawesome-svg-core';
import { faCheckCircle, faTimesCircle, faSpinner } from '@fortawesome/free-solid-svg-icons'
library.add(faCheckCircle, faTimesCircle, faSpinner)

class EncodingDashboard extends Component {
  constructor(props) {
    super(props);
    this.state = {
        encodeJobs: [],
        baseUrl: this.props.url.split('/').slice(0, -1).join('/')
    }
  }

  componentDidMount() {
      const self = this;
      this.retrieveJobs();
      this.timer = setInterval(function() {
        if(self.timer === null) {
          clearInterval(self.timer);
        } else {
          self.retrieveJobs();
        }
      }, 10000);
  }

  componentWillUnmount() {
      this.timer = null;
  }

  componentDidUpdate(prevProps, prevState) {
    const newProgress = this.state.encodeJobs.map(n => n.progress);
    if(!newProgress.some(p => p < 100)) {
        this.timer = null;
    }
  }

  retrieveJobs() {
    const self = this;
    axios({
        url: this.props.url + '.json'
    })
    .then(function(response) {
        self.setState({ encodeJobs: response.data });
    })
  }

  render() {
    const { encodeJobs, baseUrl } = this.state;

    if(encodeJobs.length > 0) {
      return (
        <Router>
          <Route exact={true} path="/encode_records" render={({ match }) => (<EncodeJobTable rows={encodeJobs} baseUrl={baseUrl} />)} />
          <Route path="/encode_records/:id" render={({ match }) => (
            <EncodeJobView job={encodeJobs.find(e => e.id == match.params.id)} /> 
          )} />
        </Router>
      );
      } else {
          return <h2>You don't have any encoding jobs yet</h2>;
      }
  }
}

export default EncodingDashboard;