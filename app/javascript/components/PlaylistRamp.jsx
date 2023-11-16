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
  MarkersDisplay,
  MetadataDisplay
} from "@samvera/ramp";
import 'video.js/dist/video-js.css';
import "@samvera/ramp/dist/ramp.css";
import { Col, Row, Tab, Tabs } from 'react-bootstrap';
import './Ramp.scss';

const Ramp = ({
  base_url,
  playlist_id,
  share,
  comment_tag,
  action_buttons
}) => {
  const [manifestUrl, setManifestUrl] = React.useState('');

  React.useEffect(() => {
    let url = `${base_url}/playlists/${playlist_id}/manifest.json`;
    setManifestUrl(url);
  }, []);

  return (
    <IIIFPlayer manifestUrl={manifestUrl}>
      <Row className="ramp--all-components">
        <Col sm={8}>
          <MediaPlayer enableFileDownload={false} />
          <MarkersDisplay />
        </Col>
        <Col sm={4}>
          <div dangerouslySetInnerHTML={{ __html: action_buttons.content }} />
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
            <Col md={12} lg={12} sm={12}>
              <div className="collapse" id="shareList">
                <div dangerouslySetInnerHTML={{ __html: share.content }} />
              </div>
            </Col>
          </Row>
          <div dangerouslySetInnerHTML={{ __html: comment_tag.content }} />
          <h4>Playlist Items</h4>
          <StructuredNavigation />
        </Col>
      </Row>
    </IIIFPlayer>
  );
};

export default Ramp;
