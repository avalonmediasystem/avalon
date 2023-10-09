/* 
 * Copyright 2011-2023, The Trustees of Indiana University and Northwestern
 *   University.  Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 * 
 * You may obtain a copy of the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software distributed
 *   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 *   CONDITIONS OF ANY KIND, either express or implied. See the License for the
 *   specific language governing permissions and limitations under the License.
 * ---  END LICENSE_HEADER BLOCK  ---
*/

import React, { Component } from 'react';
import { Modal } from 'react-bootstrap';
import ReactSME from 'react-structural-metadata-editor';
import './ReactButtonContainer.scss';

class ReactButtonContainer extends Component {
  constructor(props) {
    super(props);

    const {
      baseURL,
      masterFileID,
      mediaObjectID,
      canvasIndex,
    } = this.props;
    this.state = {
      show: false,
      smeProps: {
        structureURL: baseURL + '/master_files/' + masterFileID + '/structure.json',
        manifestURL: baseURL + '/media_objects/' + mediaObjectID + '/manifest.json',
        canvasIndex: canvasIndex,
      },
      structureSaved: true
    };
  }

  handleClose = () => {
    if (!this.state.structureSaved) {
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
  };

  render() {
    const modalID = `edit_structure_${this.props.canvasIndex}`;
    return (
      <div className="ReactButtonContainer">
        <button
          className="btn btn-primary btn-struct btn-edit mr-1"
          onClick={this.handleShow}
        >
          Edit Structure
        </button>

        <Modal
          id={modalID}
          show={this.state.show}
          animation={false}
          onHide={this.handleClose}
          backdrop="static"
          className="sme-modal-wrapper"
          dialogClassName="modal-wrapper-body">
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
