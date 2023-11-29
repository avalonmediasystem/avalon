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

const ExpandCollapseArrow = () => {
  return (
  <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" className="expand-collapse-svg" fill="currentColor" viewBox="0 0 16 16">
    <path
      fillRule="evenodd"
      d="M1.646 4.646a.5.5 0 0 1 .708 0L8 10.293l5.646-5.647a.5.5 0 0 1 .708.708l-6 6a.5.5 0 0 1-.708 0l-6-6a.5.5 0 0 1 0-.708z">
    </path>
  </svg>);
};

const Ramp = ({
  base_url,
  mo_id,
  master_files_count,
  has_structure,
  title,
  share,
  timeline,
  playlist,
  cdl,
  has_files,
  has_transcripts
}) => {
  const [manifestUrl, setManifestUrl] = React.useState('');
  const [isClosed, setIsClosed] = React.useState(false);

  let expandCollapseBtnRef = React.useRef();
  let interval;

  React.useEffect(() => {
    let url = `${base_url}/media_objects/${mo_id}/manifest.json`;
    setManifestUrl(url);

    // Attach player event listeners when there's structure
    if(has_structure) {
      interval = setInterval(addPlayerEventListeners, 500);
    }

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
      playerInst.on('loadedmetadata', () => {
        playerInst.on('timeupdate', () => {
          setIsClosed(false);
        });
      });
      // Expand sections when a new Canvas is loaded into the player
      playerInst.on('ready', () => {
        setIsClosed(false);
      });
    }
  }

  React.useEffect(() => {
    expandCollapseSections(isClosed);
  }, [isClosed]);

  const handleCollapseExpand = () => {
    setIsClosed(isClosed => !isClosed);
  }

  const expandCollapseSections = (isClosing) => {
    const allSections = $('div[class*="ramp--structured-nav__section"]');
    allSections.each(function(index, section) {
      let sectionUl = section.nextSibling;
      if(sectionUl) {
        if(isClosing) {
          sectionUl.classList.remove('expanded');
          sectionUl.classList.add('closed');
          expandCollapseBtnRef.current.classList.remove('expanded');
          expandCollapseBtnRef.current.classList.add('closed');
        } else {
          sectionUl.classList.remove('closed');
          sectionUl.classList.add('expanded');
          expandCollapseBtnRef.current.classList.remove('closed');
          expandCollapseBtnRef.current.classList.add('expanded');
        }
      }
    });
  }

  return (
    <IIIFPlayer manifestUrl={manifestUrl}>
      <Row className="ramp--all-components">
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
                        <div className="ramp--rails-content">
                          <Col className="ramp-button-group-1">
                            { timeline.canCreate &&
                              <button
                                id="timelineBtn"
                                className="btn btn-outline mr-1 text-nowrap"
                                type="button"
                                data-toggle="modal"
                                data-target="#timelineModal"
                                aria-expanded="false"
                                aria-controls="timelineModal"
                                disabled={true}
                              >
                                Create Timeline
                              </button>
                            }
                            { share.canShare &&
                              <button
                                className="btn btn-outline mr-1 text-nowrap"
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
                            { playlist.canCreate &&
                              <button className="btn btn-outline text-nowrap mr-1"
                                id="addToPlaylistBtn"
                                type="button"
                                data-toggle="collapse"
                                data-target="#addToPlaylistPanel"
                                aria-expanded="false"
                                aria-controls="addToPlaylistPanel"
                                disabled={true}
                              >
                                {/* Static SVG image in /app/assets/images/add_to_playlist_icon.svg */}
                                <svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlnsXlink="http://www.w3.org/1999/xlink" x="0px" y="0px"
                                   viewBox="-293 386 24 24" xmlSpace="preserve">
                                   <path className="st1" fill="currentColor" d="M-279,395h-12v2h12V395z M-279,391h-12v2h12V391z M-275,399v-4h-2v4h-4v2h4v4h2v-4h4v-2H-275z M-291,401h8v-2h-8V401z"/>
                                </svg>
                                Add to Playlist
                              </button>
                            }
                          </Col>
                          { has_structure &&
                            <Col className="ramp-button-group-2">
                              <button
                                className="btn btn-outline expand-collapse-toggle-button expanded"
                                id="expand_all_btn"
                                onClick={handleCollapseExpand}
                                ref={expandCollapseBtnRef}
                              >
                                <ExpandCollapseArrow />
                                {isClosed ? ' Expand' : ' Close'} {master_files_count > 1 ? `${master_files_count} Sections` : 'Section'}
                              </button>
                            </Col>
                          }
                        </div>
                        <Row className="mx-0">
                          <Col>
                            <div dangerouslySetInnerHTML={{ __html: timeline.content}} />
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
                      <StructuredNavigation />
                    </React.Fragment>
                  }
                </React.Fragment>
              )
          }
        </Col>
        <Col sm={ (master_files_count == 0) ? 12 : 4}>
          { cdl.enabled && <div dangerouslySetInnerHTML={{ __html: cdl.destroy }}/> }
          <Tabs>
            <Tab eventKey="details" title="Details">
              <MetadataDisplay showHeading={false} displayTitle={false}/>
            </Tab>
            { (cdl.can_stream && master_files_count != 0 && has_transcripts) &&
              <Tab eventKey="transcripts" title="Transcripts" className="ramp-transcripts-tab">
                <Transcript
                  playerID="iiif-media-player"
                  manifestUrl={manifestUrl}
                />
              </Tab>
            }
            { (has_files) &&
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
