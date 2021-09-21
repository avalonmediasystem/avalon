import React from 'react';
import { IIIFPlayer, MediaPlayer, StructuredNavigation, Transcript } from "@samvera/iiif-react-media-player";
import 'video.js/dist/video-js.css';
import "@samvera/iiif-react-media-player/dist/iiif-react-media-player.css";
import './ReactIIIFPlayer.scss';

const ReactIIIFPlayer = ({ manifestUrl })=> {
    return (
      <div className="IIIFMediaPlayer">
        <IIIFPlayer manifestUrl={manifestUrl} >
          <MediaPlayer />
          <StructuredNavigation />
          <Transcript
            playerID="iiif-media-player"
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
        </IIIFPlayer>
      </div>
    );
}

export default ReactIIIFPlayer;
