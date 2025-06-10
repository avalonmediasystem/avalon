/*
 * Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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
  Transcript,
  IIIFPlayer,
  MediaPlayer,
  StructuredNavigation,
  MetadataDisplay,
  SupplementalFiles
} from "@samvera/ramp";
import 'video.js/dist/video-js.css';
import "@samvera/ramp/dist/ramp.css";
import { Col, Row, Tab, Tabs } from 'react-bootstrap';
import './Ramp.scss';

const Ramp = ({
  urls,
  sections_count,
  title,
  share,
  timeline,
  playlist,
  cdl,
  has_files,
  has_transcripts
}) => {
  const [manifestUrl, setManifestUrl] = React.useState('');
  const [startCanvasId, setStartCanvasId] = React.useState();
  const [startCanvasTime, setStartCanvasTime] = React.useState();

  React.useEffect(() => {
    const { base_url, fullpath_url } = urls;
    // Split the current path from the time fragment in the format .../:id?t=time
    let [fullpath, start_time] = fullpath_url.split('?t=');
    // Split the current path in the format /media_objects/:mo_id/section/:mf_id
    let [_, __, mo_id, ___, start_canvas] = fullpath.split('/');
    // Build the manifest URL
    let url = `${base_url}/media_objects/${mo_id}/manifest.json`;

    // Set start Canvas ID and start time in the state for Ramp
    setStartCanvasId(
      start_canvas && start_canvas != undefined
        ? `${base_url}/media_objects/${mo_id}/manifest/canvas/${start_canvas}`
        : undefined
    );
    setStartCanvasTime(
      start_time && start_time != undefined
        ? parseFloat(start_time)
        : undefined
    );
    setManifestUrl(url);
  }, []);

  return (
    <IIIFPlayer manifestUrl={manifestUrl}
      customErrorMessage='This page encountered an error. Please refresh or contact an administrator.'
      startCanvasId={startCanvasId}
      startCanvasTime={startCanvasTime}>
      <Row className="ramp--all-components ramp--itemview">
        <Col sm={12} md={12} xl={8}>
          {(cdl.enabled && !cdl.can_stream)
            ? (<React.Fragment>
              <div dangerouslySetInnerHTML={{ __html: cdl.embed }} />
              <div className="ramp--rails-title">
                {<div className="object-title" dangerouslySetInnerHTML={{ __html: title.content }} />}
              </div>
            </React.Fragment>
            )
            : (<React.Fragment>
              {sections_count > 0 &&
                <React.Fragment>
                  <MediaPlayer enableFileDownload={false} enablePlaybackRate={true} />
                  <div className="ramp--rails-title">
                    {<div className="object-title" dangerouslySetInnerHTML={{ __html: title.content }} />}
                  </div>
                  <div className="ramp--rails-content">
                    <Col className="ramp-button-group-1">
                      {timeline.canCreate &&
                        <button
                          id="timelineBtn"
                          className="btn btn-outline mr-1 text-nowrap"
                          type="button"
                          data-toggle="modal"
                          data-target="#timelineModal"
                          aria-expanded="false"
                          aria-controls="timelineModal"
                          disabled={true}
                          data-testid="media-object-create-timeline-btn"
                        >
                          Create Timeline
                        </button>
                      }
                      {share.canShare &&
                        <button
                          className="btn btn-outline mr-1 text-nowrap"
                          type="button"
                          data-toggle="collapse"
                          data-target="#shareResourcePanel"
                          aria-expanded="false"
                          aria-controls="shareResourcePanel"
                          id="shareBtn"
                          data-testid="media-object-share-btn"
                        >
                          <i className="fa fa-share-alt"></i>
                          Share
                        </button>
                      }
                      {playlist.canCreate &&
                        <button className="btn btn-outline text-nowrap mr-1"
                          id="addToPlaylistBtn"
                          type="button"
                          data-toggle="collapse"
                          data-target="#addToPlaylistPanel"
                          aria-expanded="false"
                          aria-controls="addToPlaylistPanel"
                          disabled={true}
                          data-testid="media-object-add-to-playlist-btn"
                        >
                          {/* Static SVG image in /app/assets/images/add_to_playlist_icon.svg */}
                          <svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlnsXlink="http://www.w3.org/1999/xlink" x="0px" y="0px"
                            viewBox="-293 386 24 24" xmlSpace="preserve">
                            <path className="st1" fill="currentColor" d="M-279,395h-12v2h12V395z M-279,391h-12v2h12V391z M-275,399v-4h-2v4h-4v2h4v4h2v-4h4v-2H-275z M-291,401h8v-2h-8V401z" />
                          </svg>
                          Add to Playlist
                        </button>
                      }
                    </Col>
                  </div>
                  <Row className="mx-0">
                    <Col>
                      <div dangerouslySetInnerHTML={{ __html: timeline.content }} />
                    </Col>
                    <Col md={12} lg={12} sm={12} className="px-0">
                      <div className="collapse" id="addToPlaylistPanel">
                        <div className="card card-body" dangerouslySetInnerHTML={{ __html: playlist.tab }} />
                      </div>
                    </Col>
                    <Col md={12} lg={12} sm={12} className="px-0">
                      <div className="collapse" id="shareResourcePanel">
                        <div className="share-tabs" dangerouslySetInnerHTML={{ __html: share.content }} />
                      </div>
                    </Col>
                  </Row>
                  <StructuredNavigation showAllSectionsButton={true} />
                </React.Fragment>
              }
            </React.Fragment>
            )
          }
        </Col>
        <Col sm={12} md={12} xl={4} className="ramp--tabs-panel">
          {cdl.enabled && <div dangerouslySetInnerHTML={{ __html: cdl.destroy }} />}
          <Tabs>
            <Tab eventKey="details" title="Details" >
              <MetadataDisplay showHeading={false} displayTitle={false} />
            </Tab>
            {(cdl.can_stream && sections_count != 0 && has_transcripts) &&
              <Tab eventKey="transcripts" title="Transcripts" className="ramp--transcripts_tab">
                <Transcript
                  playerID="iiif-media-player"
                  manifestUrl={manifestUrl}
                />
              </Tab>
            }
            {(has_files) &&
              <Tab eventKey="files" title="Files">
                <SupplementalFiles showHeading={false} />
              </Tab>
            }
          </Tabs>
        </Col>
      </Row>
    </IIIFPlayer>
  );
};

export default Ramp;
