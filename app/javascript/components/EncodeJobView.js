import React, { Component } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

class EncodeJobView extends Component {
  constructor(props) {
    super(props);
    this.state = {
      open: false
    };
    this.accordionItems = [];
  }

  buildJSONTree = item => {
    let counter = 0;
    for (var key in item) {
      const propName = this.toTitleCase(key);
      if (item.hasOwnProperty(key)) {
        const value = item[key];
        if (Array.isArray(value)) {
          if (value.length === 0) {
            this.accordionItems.push(
              <Collapsible title={propName} key={`${key}_${counter}`}>
                <div>
                  <p>{'[ ]'}</p>
                </div>
              </Collapsible>
            );
          } else {
            this.accordionItems.push(
              <Collapsible title={propName} key={`${key}_${counter}`}>
                <div>
                  {value.map((val, index) => (
                    <Collapsible title={`${index}`} key={index}>
                      {this.buildContent(val)}
                    </Collapsible>
                  ))}
                </div>
              </Collapsible>
            );
          }
        } else if (typeof value === 'number') {
          this.accordionItems.push(
            <NonCollapsible title={propName} value={value} />
          );
        } else if (typeof value === 'object') {
          this.accordionItems.push(
            <Collapsible title={propName} key={`${key}_${counter}`}>
              <div>{this.buildContent(value)}</div>
            </Collapsible>
          );
        } else {
          this.accordionItems.push(
            <NonCollapsible title={propName} value={value} />
          );
        }
      }
      counter++;
    }
  };

  buildContent = item => {
    var props = [];
    let isEmpty = obj => {
      for (var key in obj) {
        if (obj.hasOwnProperty(key)) return false;
      }
      return true;
    };
    if (isEmpty(item)) {
      return <p>{'{ }'}</p>;
    } else if (typeof item === 'string' || typeof item === 'number') {
      return <p>{item}</p>;
    }
    for (var key in item) {
      if (item.hasOwnProperty(key)) {
        const value = item[key];
        const propName = this.toTitleCase(key);
        if (typeof value === 'number') {
          props.push(
            <p>
              <strong>{`${propName}: `}</strong>
              {value}
            </p>
          );
        } else if (value === null) {
          props.push(
            <p>
              <strong>{`${propName}: `}</strong>
              null
            </p>
          );
        } else if (typeof value === 'object') {
          this.buildJSONTree(value);
        } else {
          props.push(
            <p>
              <strong>{`${propName}: `}</strong>
              {value}
            </p>
          );
        }
      }
    }
    return props;
  };

  toTitleCase(str) {
    const splitStr = str.split('_').join(' ');
    return splitStr.replace(/\w\S*/g, function(txt) {
      return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
    });
  }

  render() {
    const { job } = this.props;
    const raw_object = JSON.parse(job.raw_object);
    this.buildJSONTree(raw_object);
    return (
      <React.Fragment>
        <h2>
          <strong>Job ID: </strong>
          {job.id}
        </h2>
        <p>
          <strong>Status: </strong>
          {job.state}
        </p>
        <p>
          <strong>Adapter: </strong>
          {job.adapter}
        </p>
        <p>
          <strong>Adapter Job ID: </strong>
          {job.global_id.split('/').reverse()[0]}
        </p>
        <p>
          <strong>Title: </strong>
          {job.display_title}
        </p>
        {raw_object.errors.length > 0 ? (
          <p>
            <strong>Error Message: </strong>
            {raw_object.errors[0]}
          </p>
        ) : (
          <React.Fragment>
            <p>
              <strong>Job Started: </strong>
              {new Date(raw_object.created_at).toLocaleString()}
            </p>
            <p>
              <strong>Job Terminated: </strong>
              {new Date(raw_object.updated_at).toLocaleString()}
            </p>
          </React.Fragment>
        )}
        <p>
          <strong>Raw Object: </strong>
        </p>
        <div className="accordion">{this.accordionItems}</div>
      </React.Fragment>
    );
  }
}

export default EncodeJobView;

class Collapsible extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      open: false,
      className: ''
    };
  }

  togglePanel = () => {
    if (this.state.className === '') {
      this.setState({ open: !this.state.open, className: ' active' });
    } else {
      this.setState({ open: !this.state.open, className: '' });
    }
  };

  render() {
    return (
      <div>
        <div
          onClick={this.togglePanel}
          className={`collapsible header${this.state.className}`}
        >
          <p>
            <strong>{`${this.props.title}: `}</strong>
            <FontAwesomeIcon
              className={`chevron${this.state.className}`}
              icon="chevron-down"
            ></FontAwesomeIcon>
          </p>
        </div>
        {this.state.open ? (
          <div className="content">{this.props.children}</div>
        ) : null}
      </div>
    );
  }
}

class NonCollapsible extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <p className="sub-heading">
        <strong>{`${this.props.title}: `}</strong>
        {this.props.value}
      </p>
    );
  }
}
