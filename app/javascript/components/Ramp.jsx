import React from 'react';
import { Transcript, IIIFPlayer, MediaPlayer, StructuredNavigation } from "@samvera/ramp";
import 'video.js/dist/video-js.css';
import "@samvera/ramp/dist/ramp.css";
import { Col, Row } from 'react-bootstrap';
import './Ramp.scss';

const Ramp = ({ base_url, mo_id, canvas_count }) => {
  const [transcriptsProp, setTrancsriptProp] = React.useState([]);
  const [manifestUrl, setManifestUrl] = React.useState('');

  React.useEffect(() => {
    setManifestUrl(`${base_url}/media_objects/${mo_id}/manifest.json`);
    buildTranscripts();
  }, []);

  const buildTranscripts = () => {
    let trProps = [];
    for(let i = 0; i < canvas_count; i++) {
      let canvasTrs = { canvasId: i, items: [] };
      canvasTrs.items = { title: '', url: manifestUrl }
      trProps.push(canvasTrs);
    }
    setTrancsriptProp(trProps);
    console.log(trProps)
  };

  return (
    <IIIFPlayer manifestUrl={manifestUrl}>
      <MediaPlayer enableFileDownload={false} />
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
