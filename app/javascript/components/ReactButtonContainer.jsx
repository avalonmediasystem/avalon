import React, { Component } from 'react';
import { Modal } from 'react-bootstrap';
import ReactSME from 'react-structural-metadata-editor';
import './ReactButtonContainer.scss';

class ReactButtonContainer extends Component {
  constructor(props) {
    super(props);

    const { audioURL, baseURL, initStructure, masterFileID, streamDuration } = this.props;
    this.state = {
      show: false,
      smeProps: {
        structureURL: baseURL + '/master_files/' + masterFileID + '/structure.json',
        waveformURL: baseURL + '/master_files/' + masterFileID + '/waveform.json',
        initStructure: initStructure,
        audioURL: audioURL,
        streamDuration: Number(streamDuration)
      },
      structureSaved: true
    };
  }

  handleClose = () => {
    if(!this.state.structureSaved) {
      if (confirm("Unsaved changes will be lost. Are you sure?")) {
        this.setState({
          show: false
        });
      }
    } else {
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

  getStructureStatus = (value) => {
    this.setState({ structureSaved: value });
  }

  render() {
    const modalID = `edit_structure_${this.props.sectionIndex}`;
    return (
      <div className="ReactButtonContainer">
        <button
          className="btn btn-primary btn-struct btn-edit mr-1"
          onClick={this.handleShow}
        >
          Edit Structure
        </button>

        <Modal id={modalID} show={this.state.show} animation={false} onHide={this.handleClose} backdrop="static" className="sme-modal-wrapper" dialogClassName="modal-wrapper-body">
          <Modal.Header closeButton>
            <Modal.Title>Edit Structure</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <ReactSME {...this.state.smeProps} structureIsSaved={this.getStructureStatus} />
          </Modal.Body>
        </Modal>
      </div>
    );
  }
}

export default ReactButtonContainer;
