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
  IIIFPlayer,
  MediaPlayer,
  StructuredNavigation,
  MetadataDisplay,
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
  urls,
  playlist_id,
  playlist_item_ids,
  token,
  share,
  comment_label,
  comment,
  tags
}) => {
  const [manifestUrl, setManifestUrl] = React.useState('');
  const [activeItemTitle, setActiveItemTitle] = React.useState();
  const [activeItemSummary, setActiveItemSummary] = React.useState();
  const [startCanvasId, setStartCanvasId] = React.useState();
  const [expanded, setExpanded] = React.useState(false);
  const [description, setDescription] = React.useState();

  let interval;
  let descriptionCheck;

  const USER_AGENT = window.navigator.userAgent;
  const IS_MOBILE = (/Mobi/i).test(USER_AGENT);

  React.useEffect(() => {
    const { base_url, fullpath_url } = urls;
    let url = `${base_url}/playlists/${playlist_id}/manifest.json`;
    if (token) url += `?token=${token}`;

    let [_, position] = fullpath_url.split('?position=');
    let start_canvas = playlist_item_ids[position - 1];
    setStartCanvasId(
      start_canvas && start_canvas != undefined
        ? `${base_url}/playlists/${playlist_id}/manifest/canvas/${start_canvas}`
        : undefined
    );
    setManifestUrl(url);

    interval = setInterval(addPlayerEventListeners, 500);
    /**
     * The passed in description is not immediately available for some reason.
     * Use an interval to wait and set initial description.
     */
    descriptionCheck = setInterval(prepInitialDescription, 100);

    // Clear intervals upon component unmounting
    return () => {
      clearInterval(interval);
      clearInterval(descriptionCheck);
    };
  }, []);

  /**
   * Listen to player's events to update the structure navigation
   * UI
   */
  const addPlayerEventListeners = () => {
    let player = document.getElementById('iiif-media-player');
    if (player && player.player != undefined && !player.player.isDisposed()) {
      let playerInst = player.player;
      playerInst.ready(() => {
        let activeElement = document.getElementsByClassName('ramp--structured-nav__tree-item active');
        if (activeElement != undefined && activeElement?.length > 0) {
          setActiveItemTitle(activeElement[0]?.dataset.label);
          setActiveItemSummary(activeElement[0]?.dataset.summary);
        }
      });
    }
  };

  const expandBtn = {
    paddingLeft: '2px',
    cursor: 'pointer'
  };

  const wordCount = 32;
  const words = comment ? comment.split(' ') : [];

  function prepInitialDescription() {
    if (words !== undefined && words.length > 0) {
      clearInterval(descriptionCheck);
      let desc = words.length > wordCount
        ? `${words.slice(0, wordCount).join(' ')}...`
        : words.join(' ');

      setDescription(desc);
    } else if (words.length === 0) {
      clearInterval(descriptionCheck);
    }
  }

  const handleDescriptionMoreLessClick = () => {
    setDescription(
      expanded ? `${words.slice(0, wordCount).join(' ')}...` : words.join(' ')
    );
    setExpanded(!expanded);
  };

  // Update scrolling indicators when end of scrolling has been reached
  const handleScrollableDescription = (e) => {
    let elem = e.target;
    const scrollMsg = elem.nextSibling;
    const structureEnd = Math.abs(elem.scrollHeight - (elem.scrollTop + elem.clientHeight)) <= 1;

    if (scrollMsg && structureEnd && scrollMsg.classList.contains('scrollable')) {
      scrollMsg.classList.remove('scrollable');
    } else if (scrollMsg && !structureEnd && !scrollMsg.classList.contains('scrollable')) {
      scrollMsg.classList.add('scrollable');
    }
  };

  // Update scrolling indicators when page is resized
  const resizeObserver = new ResizeObserver(entries => {
    for (let entry of entries) {
      handleScrollableDescription(entry);
    }
  });

  return (
    <IIIFPlayer manifestUrl={manifestUrl}
      customErrorMessage='This playlist is empty.'
      emptyManifestMessage='This playlist currently has no playable items.'
      startCanvasId={startCanvasId}>
      <Row className="ramp--all-components ramp--playlist">
        <Col sm={12} md={8}>
          <MediaPlayer enableFileDownload={false} enablePlaybackRate={true} />
          {playlist_item_ids?.length > 0 && (
            <Card className={`ramp--playlist-accordion ${IS_MOBILE ? 'mobile-view' : ''}`}>
              <Card.Header>
                <h4>{activeItemTitle}</h4>
                {activeItemSummary && <div>{activeItemSummary}</div>}
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
                      <Card.Body className="p-3">
                        <MetadataDisplay displayOnlyCanvasMetadata={true} showHeading={false} />
                      </Card.Body>
                    </Accordion.Collapse>
                    <Accordion.Toggle as={Card.Header} variant="link" eventKey="1" className="ramp--playlist-accordion-header">
                      <ExpandCollapseArrow /> Source Item Details
                    </Accordion.Toggle>
                  </Card>
                </Accordion>
              </Card.Body>
            </Card>
          )}
        </Col>
        <Col sm={12} md={4} className={`ramp--playlist-items-column ${IS_MOBILE ? 'mobile-view' : ''}`}>
          <Row>
            <Col sm={6}>
              <AutoAdvanceToggle />
            </Col>
            <Col sm={6}>
              {share.canShare &&
                <button
                  className="btn btn-outline text-nowrap float-right"
                  type="button"
                  data-toggle="collapse"
                  data-target="#shareList"
                  aria-expanded="false"
                  aria-controls="shareList"
                  id="share-button"
                  data-testid="playlist-share-btn"
                >
                  <i className="fa fa-share-alt"></i>
                  Share
                </button>
              }
            </Col>
          </Row>
          <Row className="mx-0 mb-2">
            <Col md={12} lg={12} sm={12} className="px-0">
              <div className="collapse" id="shareList">
                <div dangerouslySetInnerHTML={{ __html: share.content }} />
              </div>
            </Col>
          </Row>
          <Row className="ramp--playlist-desc-tags mx-1 mx-sm-0">
            {comment && (
              <div style={{ position: 'relative' }}>
                <h4>{comment_label}</h4>
                <div className='ramp--playlist-description' onScroll={handleScrollableDescription} data-testid="playlist-ramp-description">
                  <span dangerouslySetInnerHTML={{ __html: description }} />
                </div>
                {expanded && (
                  <div className='ramp--playlist-description-scroll scrollable'>
                    Scroll to see more
                  </div>
                )}
                {words.length > wordCount && (
                  <a className="btn-link" style={expandBtn} onClick={handleDescriptionMoreLessClick}>
                    Show {expanded ? 'less' : 'more'}
                  </a>
                )}
              </div>
            )}
            {tags && (
              <div className='ramp--playlist-tags'>
                <h4>Tags</h4>
                <div className="tag-button-wrapper" dangerouslySetInnerHTML={{ __html: tags }} />
              </div>
            )}
          </Row>
          {playlist_item_ids?.length > 0 && (
            <React.Fragment>
              <h4 className="mt-3 mx-1 mx-sm-0">Playlist Items</h4>
              <StructuredNavigation />
            </React.Fragment>
          )}
        </Col>
      </Row>
    </IIIFPlayer>
  );
};

export default Ramp;
