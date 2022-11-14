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
    const t = this;
    this.uppy = new Uppy({
      id: "uppy-file-upload",
      autoProceed: true,
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
        companionUrl: 'http://localhost:3020',
        getUploadParameters() {
          return Promise.resolve({
            method: 'POST',
            url: t.props.uploadData['url'],
            fields: t.props.uploadData['form-data']
          });
        }
      })
      .on("file-removed", (file, c, d) => {
        console.log("File Removed --- ", file, c, d);
      })
      .on("file-added", () => {
        console.log("File Added, ", t.props.uploadData);
      })
      .on("complete", function({ failed, successful }) {
        if(failed.length > 0) {
          console.log("File Upload S3 --- Error");
        }
        if(successful.length > 0) {
          console.log("File Upload S3 --- Success");
          const { uploadURL, name, size } = successful[0];
          const { container_id, step } = t.props;
          let formData = new FormData();
          const newS3URl = uploadURL.replace('http://localhost:9000/', 's3://');
          console.log(newS3URl);
          formData.append('selected_files[0][url]', newS3URl);
          formData.append('container_id', container_id);
          formData.append('step', step);

          fetch('http://localhost:3000/master_files', {
            method: 'POST',
            headers: { 'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content') },
            body: formData
          });
        }
      });
  }

  componentWillUnmount() {
    this.uppy.close();
  }

  render() {
    return (
      <React.Fragment>
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
      </React.Fragment>
    );
  }
}

export default FileUploadUppy;
