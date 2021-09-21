import React from 'react';
import { Transcript } from "@samvera/iiif-react-media-player";
import 'video.js/dist/video-js.css';
import "@samvera/iiif-react-media-player/dist/iiif-react-media-player.css";

const ReactIIIFTranscript = () => {
    return (
      <div className="IIIFMediaPlayer">
        <Transcript
          playerID="mejs-avalon-player"
          transcripts={[
            {
              canvasId: 0,
              items: [
                {
                  title: 'Canvas 1: WebVTT Transcript',
                  url: 'https://dlib.indiana.edu/iiif_av/lunchroom_manners/lunchroom_manners.vtt',
                },
                {
                  title: 'External WebVTT transcript',
                  url: 'https://dlib.indiana.edu/iiif_av/iiif-player-samples/transcripts/transcript-manifest-vtt.json',
                },
              ],
            },
            {
              canvasId: 1,
              items: [
                {
                  title: 'Canvas 2: Transcript',
                  url: 'https://dlib.indiana.edu/iiif_av/iiif-player-samples/transcripts/rendering-manifest.json',
                },
                {
                  title: 'Transcript in MS Word',
                  url: 'https://dlib.indiana.edu/iiif_av/iiif-player-samples/transcripts/transcript_ms.docx',
                },
              ],
            },
            {
              canvasId: 2,
              items: [
                {
                  title: 'Canvas 3: Transcript in MS Word',
                  url: 'https://dlib.indiana.edu/iiif_av/iiif-player-samples/transcripts/transcript_ms.docx',
                },
                {
                  title: 'Transcript',
                  url: 'https://dlib.indiana.edu/iiif_av/iiif-player-samples/transcripts/rendering-manifest.json',
                },
              ],
            },
          ]}
        />
      </div>
    );

}

export default ReactIIIFTranscript;
