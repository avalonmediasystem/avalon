import React from 'react';
import GenericTable from './GenericTable';

const EncodingJobsTable = ({ url }) => {
  const encodingTableConfig = {
    // Table metadata
    tableType: 'encoding_jobs',
    containerClass: 'encoding_jobs-table-container',
    testId: 'encoding_jobs-table',
    hasTagFilter: false,

    // Table sorting and filtering keys from parsed data
    // Order by 'Job Started' date with the latest on top
    initialSort: { columnKey: 'job_started', dataType: 'date', direction: 'desc', column: 6 },
    searchableFields: ['status', 'id', 'progress', 'filename', 'master_file', 'media_object'],

    // Column definitions
    columns: [
      { key: 'status', label: 'Status', sortable: true, dataType: 'string', width: '10%' },
      { key: 'id', label: 'ID', sortable: true, dataType: 'number', width: '5%' },
      { key: 'progress', label: 'Progress', sortable: true, dataType: 'number', width: '10%' },
      { key: 'filename', label: 'Filename', sortable: true, dataType: 'string' },
      { key: 'master_file', label: 'MasterFile', sortable: true, dataType: 'string', width: '10%' },
      { key: 'media_object', label: 'MediaObject', sortable: true, dataType: 'string', width: '10%' },
      { key: 'job_started', label: 'Job Started', sortable: true, dataType: 'date', width: '15%' }
    ],

    // Data parsing function - extracts data from Rails API response
    parseDataRow: (row, index) => {
      const parser = new DOMParser();
      const statusDoc = parser.parseFromString(row[0], 'text/html');
      const idDoc = parser.parseFromString(row[1], 'text/html');
      const progressDoc = parser.parseFromString(row[2], 'text/html');
      const masterFileDoc = parser.parseFromString(row[4], 'text/html');
      const mediaObjectDoc = parser.parseFromString(row[5], 'text/html');

      return {
        status: statusDoc.querySelector('span').textContent,
        idHtml: row[1], id: idDoc ? idDoc.querySelector('a').textContent : index,
        progressHtml: row[2], progress: progressDoc.querySelector('div').getAttribute('aria-valuenow'),
        filename: row[3],
        masterfileHtml: row[4], master_file: masterFileDoc.querySelector('a').textContent,
        mediaObjectHtml: row[5], media_object: mediaObjectDoc.querySelector('a').textContent,
        jobStarted: row[6], job_started: new Date(row[6])
      };
    },

    // Cell rendering function - how to display each cell type
    renderCell: (item, columnKey) => {
      switch (columnKey) {
        case 'status':
          return item.status;
        case 'id':
          return <div dangerouslySetInnerHTML={{ __html: item.idHtml }} />;
        case 'progress':
          return <div dangerouslySetInnerHTML={{ __html: item.progressHtml }} />;
        case 'filename':
          return item.filename;
        case 'master_file':
          return <span dangerouslySetInnerHTML={{ __html: item.masterfileHtml }} />;
        case 'media_object':
          return <span dangerouslySetInnerHTML={{ __html: item.mediaObjectHtml }} />;
        case 'job_started':
          return item.jobStarted;
        default:
          return item[columnKey];
      }
    }
  };
  return <GenericTable config={encodingTableConfig} url={url} tags={[]} />;
};

export default EncodingJobsTable;

