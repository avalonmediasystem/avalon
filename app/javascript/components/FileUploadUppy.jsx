import React from "react";
import Uppy from '@uppy/core';
import { Dashboard } from '@uppy/react';
import ActiveStorageUpload from '@excid3/uppy-activestorage-upload';
import GoogleDrive from '@uppy/google-drive';
import AwsS3 from '@uppy/aws-s3';

require('@uppy/core/dist/style.css')
require('@uppy/dashboard/dist/style.css')

class FileUploadUppy extends React.Component {
  constructor(props) {
    super(props);
    // this.state = {
    //   dirUploadURL: document.querySelector("meta[name='direct-upload-url']").getAttribute("content"),
    // };
  }  

  componentWillMount() {
    this.uppy = new Uppy({
      id: "uppy-file-upload",
      // autoProceed: false,
      restrictions: {
        allowedFileTypes: [".mp4", ".mp3"]
      },
    });

    this.uppy
      // .use(ActiveStorageUpload, {
      //   directUploadUrl: this.state.dirUploadURL
      // })
      .use(GoogleDrive, {
        companionUrl: 'http://localhost:3020'
      })
      .use(AwsS3, {
        // limit: 2,
        // timeout: ms('1 minute'),
        companionUrl: 'http://localhost:3020',
      })
      .on("file-removed", (file, c, d) => {
        console.log("---", file, c, d);
      })
      .on("file-added", () => {
        console.log("file added");
      })
      .on("upload-success", () => {
        console.log("ddd");
      })
      .on("complete", function() {
        console.log('complete');
      });
  }

  componentWillUnmount() {
    this.uppy.close();
  }

  render() {
    return (
      <React.Fragment>
        <form >
          <Dashboard
            uppy={this.uppy}
            plugins={["GoogleDrive"]}
            proudlyDisplayPoweredByUppy={false}
            showProgressDetails={true}
            hideUploadButton={false}
            target="body"
          />
          <style>
            {`.uppy-Dashboard-inner {
                z-index: 0 !important
            }`}
          </style>
        </form>
      </React.Fragment>
    );
  }
}

export default FileUploadUppy;
