import React from 'react';
import { Transcript } from "@samvera/iiif-react-media-player";
import 'video.js/dist/video-js.css';
import "@samvera/iiif-react-media-player/dist/iiif-react-media-player.css";

const ReactIIIFTranscript = ({ base_url, transcripts }) => {
  const [transcriptsProp, setTrancsriptProp] = React.useState([]);
  // Check for at least one masterfile in the mediaobject has a transcript file
  const [hasTranscript, setHasTranscript] = React.useState(false);

  React.useEffect(() => {
    buildTranscriptUrls();
  }, [])

  const buildTranscriptUrls = () => {
    let trProps = [];
    transcripts.forEach((tr, i) => {
      let transcriptItems = tr.transcripts;
      let canvasTrs = { canvasId: i, items: [] }

      // construct URLs as expected within the transcript component
      if(transcriptItems.length > 0) {
        setHasTranscript(true)
        canvasTrs.items = transcriptItems.map(
          t => (
            { title: t.label,
              url: `${base_url}/master_files/${tr.id}/transcript/${t.id}`
            }
          )
        )
      }
      trProps.push(canvasTrs)
    });    
    setTrancsriptProp(trProps)
  }
  
  // Render the transcript component if at least one masterfile (canvas in manifest)
  // has a transcript file
  if(hasTranscript) {
    return (
      <div className="IIIFMediaPlayer">
        <Transcript
          playerID="mejs-avalon-player"
          transcripts={transcriptsProp}
        />
      </div>
    );
  } else {
    return null;
  }
}

export default ReactIIIFTranscript;
