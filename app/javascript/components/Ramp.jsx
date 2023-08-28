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
  SupplmentalFiles 
} from "@samvera/ramp";
import 'video.js/dist/video-js.css';
import "@samvera/ramp/dist/ramp.css";
import { Col, Row, Tab, Tabs } from 'react-bootstrap';
import './Ramp.scss';

const Ramp = ({ 
  base_url, 
  mo_id, 
  master_files_count, 
  share, 
  timeline, 
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
      <Row>
        {!in_progress &&
          <Col sm={8}>
            { (cdl.enabled && !cdl.can_stream) 
              ? (<div dangerouslySetInnerHTML={{ __html: cdl.embed }} />)
              : ( <React.Fragment>
                    { master_files_count > 0 && 
                      <React.Fragment>
                        <MediaPlayer enableFileDownload={false} />
                        <div className="ramp--rails-content">
                          { timeline.canCreate && <div className="mr-1" dangerouslySetInnerHTML={{ __html: timeline.content }} /> }
                          { share.canShare && <div className="share-tabs" dangerouslySetInnerHTML={{ __html: share.content }} /> }
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
              <SupplmentalFiles showHeading={false} />
            </Tab>
          </Tabs>
        </Col>
      </Row>
    </IIIFPlayer>
  );
};

export default Ramp;
