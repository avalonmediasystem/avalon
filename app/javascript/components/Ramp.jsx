import React from 'react';
import { Transcript, IIIFPlayer, MediaPlayer, StructuredNavigation, MetadataDisplay, SupplmentalFiles } from "@samvera/ramp";
import 'video.js/dist/video-js.css';
import "@samvera/ramp/dist/ramp.css";
import { Col, Row, Tab, Tabs } from 'react-bootstrap';
import './Ramp.scss';

const Ramp = ({ base_url, mo_id, canvas_count, share, timeline, cdl, progress }) => {
  const [transcriptsProp, setTrancsriptProp] = React.useState([]);
  const [manifestUrl, setManifestUrl] = React.useState('');

  const { enabled, canStream, embed, destroyCDL } = cdl;
  React.useEffect(() => {
    let url = `${base_url}/media_objects/${mo_id}/manifest.json`;
    setManifestUrl(url);
    buildTranscripts(url);
  }, []);

  const buildTranscripts = (url) => {
    let trProps = [];
    for(let i = 0; i < canvas_count; i++) {
      let canvasTrs = { canvasId: i, items: [] };
      canvasTrs.items = [{ title: '', url }];
      trProps.push(canvasTrs);
    }
    setTrancsriptProp(trProps);
  };

  return (
    <IIIFPlayer manifestUrl={manifestUrl}>
      <Row>
        <Col>
          { (enabled && !canStream) && (<div dangerouslySetInnerHTML={{ __html: embed }} />) }
          <React.Fragment>
            <div dangerouslySetInnerHTML={{ __html: progress }} />
            <MediaPlayer enableFileDownload={false} />
            <div className="ramp--rails-content">
              { timeline.canCreate && <div className="mr-1" dangerouslySetInnerHTML={{ __html: timeline.content }} /> }
              { share.canShare && <div className="share-tabs" dangerouslySetInnerHTML={{ __html: share.content }} /> }
            </div>
            <StructuredNavigation />
          </React.Fragment>
        </Col>
        <Col>
          { enabled && <div dangerouslySetInnerHTML={{ __html: destroyCDL }}/> }
          <Tabs>
            <Tab eventKey="details" title="Details">
              <MetadataDisplay showHeading={false} displayTitle={false}/>
            </Tab>
            <Tab eventKey="transcripts" title="Transcripts">
              <Transcript
                playerID="iiif-media-player"
                transcripts={transcriptsProp}
              />
            </Tab>
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
