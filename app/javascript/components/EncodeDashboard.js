import React, { Component } from 'react';
import axios from 'axios';
import { BrowserRouter as Router, Route } from 'react-router-dom';
import EncodeJobView from './EncodeJobView';
import EncodeJobTable from './EncodeJobTable';

import './EncodeDashboard.scss';

import { library } from '@fortawesome/fontawesome-svg-core';
import {
  faCheckCircle,
  faTimesCircle,
  faSpinner,
  faChevronDown,
  faChevronUp
} from '@fortawesome/free-solid-svg-icons';
library.add(
  faCheckCircle,
  faTimesCircle,
  faSpinner,
  faChevronDown,
  faChevronUp
);

class EncodeDashboard extends Component {
  constructor(props) {
    super(props);
    this.state = {
      encodeJobs: [],
      baseUrl: this.props.url
        .split('/')
        .slice(0, -1)
        .join('/'),
      fetchingData: true
    };
  }

  componentDidMount() {
    const self = this;
    this.retrieveJobs();
    this.timer = setInterval(function() {
      if (self.timer === null) {
        clearInterval(self.timer);
      } else {
        self.retrieveJobs();
      }
    }, 10000);
  }

  componentWillUnmount() {
    this.timer = null;
  }

  componentDidUpdate() {
    this.state.encodeJobs.map(job => {
      if (job.state !== 'running' && job.progress < 100) {
        this.timer = null;
      }
    });
  }

  retrieveJobs() {
    const self = this;
    axios({
      url: this.props.url + '.json'
    })
      .then(function(response) {
        self.setState({ encodeJobs: response.data, fetchingData: false });
      })
      .catch(function(error) {
        self.setState({ fetchingData: false });
        console.log(error);
      });
  }

  render() {
    const { encodeJobs, baseUrl, fetchingData } = this.state;

    if (fetchingData) {
      return <h1>Transcoding Dashboard</h1>;
    } else {
      return encodeJobs.length > 0 ? (
        <Router>
          <Route
            exact={true}
            path="/encode_records"
            render={() => (
              <EncodeJobTable rows={encodeJobs} baseUrl={baseUrl} />
            )}
          />
          <Route
            path="/encode_records/:id"
            render={({ match }) => (
              <EncodeJobView
                job={encodeJobs.find(e => e.id == match.params.id)}
              />
            )}
          />
        </Router>
      ) : (
        <h2>You don't have any encoding jobs yet</h2>
      );
    }
  }
}

export default EncodeDashboard;
