import React from 'react';
import { Transcript } from "@samvera/iiif-react-media-player";
import 'video.js/dist/video-js.css';
import "@samvera/iiif-react-media-player/dist/iiif-react-media-player.css";

const ReactIIIFTranscript = ({ base_url, transcripts }) => {
  const [transcriptsProp, setTrancsriptProp] = React.useState([]);

  React.useEffect(() => {
    buildTranscriptUrls();
  }, [])

  const buildTranscriptUrls = () => {
    let trProps = [];
    transcripts.forEach((tr, i) => {
      let transcriptItems = tr.transcripts;
      let canvasTrs = {
        canvasId: i,
        items: transcriptItems.length > 0
                ? transcriptItems.map(
                    t => (
                      { title: t.label,
                        url: `${base_url}/master_files/${tr.id}/transcript/${t.id}/${t.label}`
                      }
                    )
                  )
                : []
      }
      console.log(tr)
      trProps.push(canvasTrs)
    });
    console.log(trProps);
    
    setTrancsriptProp(trProps)
  }
  
  return (
    <div className="IIIFMediaPlayer">
      <Transcript
        playerID="mejs-avalon-player"
        transcripts={transcriptsProp}
      />
    </div>
  );

}

export default ReactIIIFTranscript;
