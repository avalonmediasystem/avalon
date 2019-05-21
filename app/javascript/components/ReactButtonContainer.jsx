import React, { Component } from 'react';
import { Modal, Button } from 'react-bootstrap';
import ReactSME from 'react-structural-metadata-editor';
import './ReactButtonContainer.css';

class ReactButtonContainer extends Component {
  constructor(props) {
    super(props);

    this.state = {
      show: false,
      smeProps: {
        masterFileID: this.props.masterFileID,
        baseURL: this.props.baseURL,
        initStructure: this.props.initStructure,
        audioStreamURL: this.props.audioStreamURL
      }
    };
  }

  handleClose = () => {
    if (confirm("Unsaved changes will be lost. Are you sure?")) {
      this.setState({
        show: false
      });
    }
  };

  handleShow = e => {
    e.preventDefault();
    this.setState({
      show: true
    });
  };

  render() {
    const modalID = `edit_structure_${this.props.sectionIndex}`;
    return (
      <div className="ReactButtonContainer">
        <button
          className="btn btn-primary btn-xs btn-edit"
          onClick={this.handleShow}
        >
          Edit Structure
        </button>

        <Modal id={modalID} show={this.state.show} animation={false} onHide={this.handleClose} backdrop="static" className="sme-modal-wrapper" dialogClassName="modal-wrapper-body">
          <Modal.Header closeButton>
            <Modal.Title>Edit Structure</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <ReactSME {...this.state.smeProps} />
          </Modal.Body>
        </Modal>
      </div>
    );
  }
}

export default ReactButtonContainer;
