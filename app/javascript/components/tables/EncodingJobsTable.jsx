import React, { useState, useCallback } from 'react';
import GenericTable from './GenericTable';
import useProgressUpdates from './hooks/useProgressUpdates';

/**
 * Render a table displaying encoding job records.
 * @param {Object} props
 * @param {String} props.url API endpoint URL for fetching encoding jobs data
 * @param {String} props.progressUrl API endpoint URL for fetching encoding jobs progress updates 
 */
const EncodingJobsTable = ({ url, progressUrl }) => {
  // State for managing progress updates
  const [progressData, setProgressData] = useState({});
  const [currentJobs, setCurrentJobs] = useState([]);

  // Callback to handle progress updates from the hook
  const handleProgressUpdate = useCallback((newProgressData) => {
    setProgressData(prevData => ({
      ...prevData,
      ...newProgressData
    }));
  }, []);

  // Initialize progress updates hook
  useProgressUpdates({ currentJobs, onProgressUpdate: handleProgressUpdate, progressUrl });

  /**
   * Get CSS classes for progress bar based on job status
   * @param {String} status encoding job status
   * @returns {String} CSS class string
   */
  const getProgressBarClasses = useCallback((status) => {
    const baseClasses = ['progress progress-bar'];
    const statusLower = status?.toLowerCase();

    if (statusLower) {
      baseClasses.push(statusLower);

      if (['cancelled', 'failed'].includes(statusLower)) {
        baseClasses.push('progress-bar-striped');
      } else if (statusLower === 'running') {
        baseClasses.push('progress-bar-striped', 'progress-bar-animated');
      }
    }

    return baseClasses.join(' ');
  }, []);

  const encodingTableConfig = {
    // Table metadata and configuration
    tableType: 'encoding_jobs',
    containerClass: 'encoding_jobs-table-container',
    testId: 'encoding_jobs-table',
    hasTagFilter: false,

    // Pagination options
    pageSizeOptions: [10, 20, 50, 100],
    initPageSize: 20,

    // Table sorting and filtering keys from parsed data
    // Order by 'Job Started' date with the latest on top
    initialSort: { columnKey: 'job_started', dataType: 'date', direction: 'desc', column: 6 },
    searchableFields: ['status', 'id', 'filename', 'master_file', 'media_object'],

    // Column definitions
    columns: [
      { key: 'status', label: 'Status', sortable: true, dataType: 'string', width: '10%' },
      { key: 'id', label: 'ID', sortable: true, dataType: 'number', width: '5%' },
      // Make progress column non-sortable as the active progress values are not updated in state
      { key: 'progress', label: 'Progress', sortable: false, width: '10%' },
      { key: 'filename', label: 'Filename', sortable: true, dataType: 'string' },
      { key: 'master_file', label: 'MasterFile', sortable: true, dataType: 'string', width: '10%' },
      { key: 'media_object', label: 'MediaObject', sortable: true, dataType: 'string', width: '10%' },
      { key: 'job_started', label: 'Job Started', sortable: true, dataType: 'date', width: '15%' }
    ],

    // Data parsing function to extract data from Rails API response
    parseDataRow: useCallback((row, index) => {
      const parser = new DOMParser();
      const statusDoc = parser.parseFromString(row[0], 'text/html');
      const idDoc = parser.parseFromString(row[1], 'text/html');
      const progressDoc = parser.parseFromString(row[2], 'text/html');
      const progressValue = progressDoc.querySelector('div').getAttribute('aria-valuenow');
      const masterFileDoc = parser.parseFromString(row[4], 'text/html');
      const mediaObjectDoc = parser.parseFromString(row[5], 'text/html');

      // Extract encode ID from the status span's data attribute
      const statusSpan = statusDoc.querySelector('span[data-encode-id]');
      const encode_id = statusSpan ? statusSpan.getAttribute('data-encode-id') : null;

      let jobData = {
        encode_id: encode_id,
        status: statusDoc.querySelector('span').textContent,
        id_html: row[1], id: idDoc ? idDoc.querySelector('a').textContent : index,
        progress_html: row[2], progress: parseFloat(progressValue) || 0,
        filename: row[3],
        masterfile_html: row[4], master_file: masterFileDoc.querySelector('a').textContent,
        mediaobject_html: row[5], media_object: mediaObjectDoc.querySelector('a').textContent,
        jobstarted_html: row[6], job_started: new Date(row[6])
      };
      // Merge any existing progress data for this encode ID
      const updatedData = progressData[encode_id];
      if (updatedData) {
        jobData = { ...jobData, ...updatedData };
      }

      return jobData;
    }, [progressData]),

    // Callback when data is parsed and available
    onDataParsed: (parsedData) => {
      setCurrentJobs(parsedData);
    },

    // Cell rendering function for each column key
    renderCell: useCallback((item, columnKey) => {
      // Get updated progress data if available
      const updatedData = progressData[item.encode_id];

      switch (columnKey) {
        case 'status':
          return updatedData ? updatedData.status : item.status;
        case 'id':
          return <div dangerouslySetInnerHTML={{ __html: item.id_html }} />;
        case 'progress':
          if (updatedData) {
            // Create dynamic progress bar with updated data
            const progressBarClasses = getProgressBarClasses(updatedData.status);

            return (
              <div
                className={progressBarClasses}
                data-encode-id={item.encode_id}
                aria-valuenow={updatedData.progress}
                aria-valuemin="0"
                aria-valuemax="100"
                style={{ width: `${updatedData.progress}%` }}
              />
            );
          }
          return <div dangerouslySetInnerHTML={{ __html: item.progress_html }} />;
        case 'filename':
          return item.filename;
        case 'master_file':
          return <span dangerouslySetInnerHTML={{ __html: item.masterfile_html }} />;
        case 'media_object':
          return <span dangerouslySetInnerHTML={{ __html: item.mediaobject_html }} />;
        case 'job_started':
          return item.jobstarted_html;
        default:
          return item[columnKey];
      }
    }, [progressData])
  };

  return <GenericTable config={encodingTableConfig} url={url} tags={[]} />;
};

export default EncodingJobsTable;

