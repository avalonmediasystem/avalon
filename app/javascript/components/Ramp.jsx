import React from 'react';
import { Transcript, IIIFPlayer, MediaPlayer, StructuredNavigation } from "@samvera/ramp";
import 'video.js/dist/video-js.css';
import "@samvera/ramp/dist/ramp.css";
import { Col, Row } from 'react-bootstrap';
import './Ramp.scss';

const Ramp = ({ base_url, mo_id, canvas_count, share, timeline }) => {
  const [transcriptsProp, setTrancsriptProp] = React.useState([]);
  const [manifestUrl, setManifestUrl] = React.useState('');

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
      <MediaPlayer enableFileDownload={false} />
      <div className="ramp--rails-content">
        { timeline.canCreate && <div className="mr-1" dangerouslySetInnerHTML={{ __html: timeline.content }} /> }
        { share.canShare && <div className="share-tabs" dangerouslySetInnerHTML={{ __html: share.content }} /> }
      </div>
      <Row>
        <Col>
          <StructuredNavigation />
        </Col>
        <Col>
          <Transcript
            playerID="iiif-media-player"
            transcripts={transcriptsProp}
          />
        </Col>
      </Row>
    </IIIFPlayer>
  );
};

export default Ramp;
