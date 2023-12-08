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

import React from 'react';
import {
  IIIFPlayer,
  MediaPlayer,
  StructuredNavigation,
  AutoAdvanceToggle,
  MarkersDisplay
} from "@samvera/ramp";
import 'video.js/dist/video-js.css';
import "@samvera/ramp/dist/ramp.css";
import { Accordion, Card, Col, Row } from 'react-bootstrap';
import './Ramp.scss';

const ExpandCollapseArrow = () => {
  return (
  <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" className="accordion-arrow" fill="currentColor" viewBox="0 0 16 16">
    <path
      fillRule="evenodd"
      d="M1.646 4.646a.5.5 0 0 1 .708 0L8 10.293l5.646-5.647a.5.5 0 0 1 .708.708l-6 6a.5.5 0 0 1-.708 0l-6-6a.5.5 0 0 1 0-.708z">
    </path>
  </svg>);
};

const Ramp = ({
  base_url,
  playlist_id,
  share,
  comment_tag
}) => {
  const [manifestUrl, setManifestUrl] = React.useState('');
  const [activeItemTitle, setActiveItemTitle] = React.useState();

  let interval;

  React.useEffect(() => {
    let url = `${base_url}/playlists/${playlist_id}/manifest.json`;
    setManifestUrl(url);

    interval = setInterval(addPlayerEventListeners, 500);

    // Clear interval upon component unmounting
    return () => clearInterval(interval);
  }, []);

  /**
   * Listen to player's events to update the structure navigation
   * UI
   */
  const addPlayerEventListeners = () => {
    let player = document.getElementById('iiif-media-player');
    if(player && player.player != undefined && !player.player.isDisposed()) {
      let playerInst = player.player;
      let canvasIndex = parseInt(player.dataset.canvasindex);
      playerInst.on('loadedmetadata', () => {
        let activeElements = document.getElementsByClassName('ramp--structured-nav__list-item');
        if(activeElements != undefined && activeElements?.length > 0) {
          setActiveItemTitle(activeElements[canvasIndex].textContent);
        }
      });
    }
  }

  return (
    <IIIFPlayer manifestUrl={manifestUrl}>
      <Row className="ramp--all-components ramp--playlist">
        <Col sm={8}>
          <MediaPlayer enableFileDownload={false} />
          <Card className="ramp--playlist-accordion">
              <Card.Header>
                <h4>{activeItemTitle}</h4>
              </Card.Header>
              <Card.Body>
                <Accordion>
                  <Card>
                    <Accordion.Collapse eventKey="0" id="markers">
                      <Card.Body>
                        <MarkersDisplay showHeading={false} />
                      </Card.Body>
                    </Accordion.Collapse>
                    <Accordion.Toggle as={Card.Header} variant="link" eventKey="0" className="ramp--playlist-accordion-header">
                      <ExpandCollapseArrow /> Markers
                    </Accordion.Toggle>
                  </Card>
                  <Card>
                    <Accordion.Collapse eventKey="1">
                      <Card.Body>

                      </Card.Body>
                    </Accordion.Collapse>
                    <Accordion.Toggle as={Card.Header} variant="link" eventKey="1" className="ramp--playlist-accordion-header">
                      <ExpandCollapseArrow /> Source Item Details
                    </Accordion.Toggle>
                  </Card>
                </Accordion>
              </Card.Body>
          </Card>
        </Col>
        <Col sm={4}>
          <Row>
            <Col sm={6}>
              <AutoAdvanceToggle />
            </Col>
            <Col sm={6}>
              { share.canShare &&
                <button
                  className="btn btn-outline text-nowrap float-right"
                  type="button"
                  data-toggle="collapse"
                  data-target="#shareList"
                  aria-expanded="false"
                  aria-controls="shareList"
                  id="share-button"
                >
                  <i className="fa fa-share-alt"></i>
                    Share
                </button>
              }
            </Col>
          </Row>
          <Row className="mx-0">
            <Col md={12} lg={12} sm={12} className="px-0">
              <div className="collapse" id="shareList">
                <div dangerouslySetInnerHTML={{ __html: share.content }} />
              </div>
            </Col>
          </Row>
          <div dangerouslySetInnerHTML={{ __html: comment_tag.content }} />
          <h4 className="mt-3">Playlist Items</h4>
          <StructuredNavigation />
        </Col>
      </Row>
    </IIIFPlayer>
  );
};

export default Ramp;
