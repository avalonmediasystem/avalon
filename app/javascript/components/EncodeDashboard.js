import React, { Component } from 'react';
import axios from 'axios';
import { BrowserRouter as Router, Route } from 'react-router-dom';
import EncodeJobView from './EncodeJobView';
import EncodeJobTable from './EncodeJobTable';
import './EncodeDashboard.scss';
import { library } from '@fortawesome/fontawesome-svg-core';
import { faCheckCircle, faTimesCircle, faSpinner, faChevronDown, faChevronUp } from '@fortawesome/free-solid-svg-icons';
library.add( faCheckCircle, faTimesCircle, faSpinner, faChevronDown, faChevronUp );

let intervalTimer = '';

class EncodeDashboard extends Component {
  constructor(props) {
    super(props);
    this.state = {
      encodeJobs: [],
      baseUrl: this.props.url
        .split('/')
        .slice(0, -1)
        .join('/'),
      fetchingData: true,
      isStopped: false,
      isFirstLoad: true
    };
  }

  componentDidMount() {
    this.retrieveJobs();
    const self = this;
    intervalTimer = setInterval(function() { self.retrieveJobs() }, 10000);
  }

  componentWillUnmount() { clearInterval(intervalTimer) }

  static getDerivedStateFromProps(nextProps, prevState) {
    if (prevState.isStopped) { clearInterval(intervalTimer) }
    return null;
  }

  retrieveJobs() {
    const isRunning = this.state.encodeJobs.map(j => j.state).filter(e => e === 'running');
    if (this.state.isFirstLoad) {
      this.fetchDataHandler();
    } else {
      if (isRunning.length === 0) {
        this.setState({ isStopped: true, fetchingData: false });
      } else {
        this.fetchDataHandler();
      }
    }
  }

  fetchDataHandler() {
    const self = this;
    axios({
      url: self.props.url + '.json'
    })
      .then(function(response) {
        self.setState({ encodeJobs: response.data, fetchingData: false, isFirstLoad: false
        });
      })
      .catch(function(error) {
        self.setState({ fetchingData: false, isFirstLoad: false });
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
          <Route exact={true} path="/encode_records" render={() => ( <EncodeJobTable rows={encodeJobs} baseUrl={baseUrl} /> )} />
          <Route path="/encode_records/:id" render={({ match }) => (
              <EncodeJobView job={encodeJobs.find(e => e.id == match.params.id)} accordionItems={[]} /> )} />
        </Router>
      ) : (
        <React.Fragment>
          <h1>Transcoding Dashboard</h1>
          <h2>You don't have any encoding jobs yet</h2>
        </React.Fragment>
      );
    }
  }
}

export default EncodeDashboard;
