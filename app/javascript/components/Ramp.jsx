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
  base_url,
  mo_id,
  master_files_count,
  title,
  expand_structure,
  admin_links,
  share,
  timeline,
  playlist,
  thumbnail,
  in_progress,
  cdl
}) => {
  const [manifestUrl, setManifestUrl] = React.useState('');

  React.useEffect(() => {
    let url = `${base_url}/media_objects/${mo_id}/manifest.json`;
    setManifestUrl(url);
  }, []);

  return (
    <IIIFPlayer manifestUrl={manifestUrl}>
      <Row className="ramp--all-components">
        {!in_progress &&
          <Col sm={8}>
            { (cdl.enabled && !cdl.can_stream)
              ? (<div dangerouslySetInnerHTML={{ __html: cdl.embed }} />)
              : ( <React.Fragment>
                    { master_files_count > 0 &&
                      <React.Fragment>
                        <MediaPlayer enableFileDownload={false} />
                        <div className="ramp--rails-title">
                          { <div className="object-title" dangerouslySetInnerHTML={{ __html: title.content }} /> }
                        </div>
                          <div  className="ramp--rails-content">
                            <Col className="ramp-button-group-1">
                              { timeline.canCreate && <div className="mr-1" dangerouslySetInnerHTML={{ __html: timeline.content }} /> }
                              { playlist.canCreate && 
                                <button className="btn btn-outline mr-1"
                                  id="addToPlaylistBtn"
                                  type="button"
                                  data-toggle="collapse"
                                  data-target="#addToPlaylistPanel"
                                  aria-expanded="false"
                                  aria-controls="addToPlaylistPanel"
                                  disabled={true}
                                >
                                  Add to Playlist
                                </button>
                              }
                              { share.canShare && 
                                <button 
                                  className="btn btn-outline"
                                  type="button"
                                  data-toggle="collapse"
                                  data-target="#shareResourcePanel"
                                  aria-expanded="false"
                                  aria-controls="shareResourcePanel"
                                  id="shareBtn"
                                >
                                  <i className="fa fa-share-alt"></i>
                                    Share
                                </button>
                              }
                            </Col>
                            <Col className="ramp-button-group-2">
                              { admin_links.canUpdate && <div className="mr-1" dangerouslySetInnerHTML={{ __html: admin_links.content }} /> }
                              { thumbnail.canCreate && <div className="mr-1" dangerouslySetInnerHTML={{ __html: thumbnail.content }} /> }
                            </Col>
                          </div>
                          <Row className="mx-0">
                            <Col md={12} lg={12} sm={12}>
                              <div className="collapse" id="addToPlaylistPanel">
                                <div className="card card-body" dangerouslySetInnerHTML={{ __html: playlist.tab }} />
                              </div>
                            </Col>
                            <Col md={12} lg={12} sm={12}>
                              <div className="collapse" id="shareResourcePanel">
                                <div className="card card-body share-tabs" dangerouslySetInnerHTML={{ __html: share.content }} />
                              </div>
                            </Col>
                          </Row>
                        <div className="ramp--rails-expand-structure">
                          { <div className="mr-1" dangerouslySetInnerHTML={{ __html: expand_structure.content }} /> }
                        </div>
                        <StructuredNavigation />
                      </React.Fragment>
                    }
                  </React.Fragment>
                )
            }
          </Col>
        }
        <Col sm={ (in_progress || master_files_count == 0) ? 12 : 4}>
          { cdl.enabled && <div dangerouslySetInnerHTML={{ __html: cdl.destroy }}/> }
          <Tabs>
            <Tab eventKey="details" title="Details">
              <MetadataDisplay showHeading={false} displayTitle={false}/>
            </Tab>
            { (cdl.can_stream && master_files_count != 0 && !in_progress) &&
              <Tab eventKey="transcripts" title="Transcripts">
                <Transcript
                  playerID="iiif-media-player"
                  manifestUrl={manifestUrl}
                />
              </Tab>
            }
            <Tab eventKey="files" title="Files">
              <SupplementalFiles showHeading={false} />
            </Tab>
          </Tabs>
        </Col>
      </Row>
    </IIIFPlayer>
  );
};

export default Ramp;
