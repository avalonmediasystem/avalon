import React from 'react';
import { Transcript, IIIFPlayer, MediaPlayer, StructuredNavigation } from "@samvera/ramp";
import 'video.js/dist/video-js.css';
import "@samvera/ramp/dist/ramp.css";
import './Ramp.scss';

const Ramp = ({ base_url, transcripts, mo_id }) => {
  const [transcriptsProp, setTrancsriptProp] = React.useState([]);
  // Check for at least one masterfile in the mediaobject has a transcript file
  const [hasTranscript, setHasTranscript] = React.useState(false);
  const [manifestUrl, setManifestUrl] = React.useState('');

  React.useEffect(() => {
    buildTranscriptUrls();
    setManifestUrl(`${base_url}/media_objects/${mo_id}/manifest.json`);
  }, []);

  const buildTranscriptUrls = () => {
    let trProps = [];
    transcripts.forEach((tr, i) => {
      let transcriptItems = tr.transcripts;
      let canvasTrs = { canvasId: i, items: [] };

      // construct URLs as expected within the transcript component
      if (transcriptItems.length > 0) {
        setHasTranscript(true);
        canvasTrs.items = transcriptItems.map(
          t => (
            {
              title: t.label,
              url: `${base_url}/master_files/${tr.id}/transcript/${t.id}`
            }
          )
        );
      }
      trProps.push(canvasTrs);
    });
    setTrancsriptProp(trProps);
  };

  // Render the transcript component if at least one masterfile (canvas in manifest)
  // has a transcript file
  return (
    <IIIFPlayer manifestUrl={manifestUrl}>
      <MediaPlayer enableFileDownload={false} />
      <StructuredNavigation />
      {hasTranscript &&
        (<Transcript
          playerID="iiif-media-player"
          transcripts={transcriptsProp}
        />)
      }
    </IIIFPlayer>
  );
};

export default Ramp;
