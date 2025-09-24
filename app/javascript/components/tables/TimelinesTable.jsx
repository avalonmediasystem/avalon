import React from 'react';
import GenericTable from './GenericTable';

/**
 * Render a table displaying timelines of the current user.
 * @param {Object} props
 * @param {String} props.url API endpoint URL for fetching timelines data
 * @param {Array} props.tags array of available tags for filtering 
 */
const TimelinesTable = ({ url, tags }) => {
  const timelineConfig = {
    // Table metadata
    tableType: 'timeline',
    containerClass: 'timeline-table-container',
    testId: 'timeline-table',
    hasTagFilter: true,

    // Table sorting and filtering keys from parsed data (keys match column keys and parsed data keys)
    initialSort: { columnKey: 'title' },
    searchableFields: ['title', 'description'],

    // Column definitions
    columns: [
      { key: 'title', label: 'Name', sortable: true, dataType: 'string', width: '15%' },
      { key: 'description', label: 'Description', sortable: true, dataType: 'string', width: '30%' },
      { key: 'visibility', label: 'Visibility', sortable: true, dataType: 'string', width: '10%' },
      { key: 'updated_at', label: 'Last Updated', sortable: true, dataType: 'date', width: '10%' },
      { key: 'tags', label: 'Tags', sortable: true, dataType: 'string', width: '10%' },
      { key: 'actions', label: 'Actions', sortable: false, width: '25%' },
    ],

    // Data parsing function to extract data from Rails API response
    parseDataRow: (row, index) => {
      const parser = new DOMParser();
      // Extract timeline id name from title link HTML
      const titleDoc = parser.parseFromString(row[0], 'text/html').querySelector('a');
      const titleLink = titleDoc.getAttribute('href');

      // Extract clean visibility text from HTML for sorting
      const visibilityDoc = parser.parseFromString(row[2], 'text/html').querySelector('span');

      // Extract and parse last updated datetime into Date object for sorting
      const lastUpdatedDoc = parser.parseFromString(row[3], 'text/html').querySelector('span');
      const lastUpdateTime = lastUpdatedDoc.getAttribute('title');

      return {
        id: titleLink ? titleLink.split('/').pop() : index,
        title_html: row[0], title: titleDoc ? titleDoc.textContent : '',
        description: row[1],
        visibility: visibilityDoc ? visibilityDoc.textContent : '', visibility_html: row[2],
        udated_html: row[3], updated_at: new Date(lastUpdateTime),
        tags: row[4], actions_html: row[5]
      };
    },

    // Cell rendering function for each column key
    renderCell: (item, columnKey) => {
      switch (columnKey) {
        case 'title':
          return (
            <div dangerouslySetInnerHTML={{ __html: item.title_html }} />
          );
        case 'description':
          return item.description;
        case 'visibility':
          return <span dangerouslySetInnerHTML={{ __html: item.visibility_html }} />;
        case 'updated_at':
          return (
            <div dangerouslySetInnerHTML={{ __html: item.udated_html }} />
          );
        case 'tags':
          return item.tags;
        case 'actions':
          return (
            <div
              className="text-end"
              dangerouslySetInnerHTML={{ __html: item.actions_html }}
            />
          );
        default:
          return item[columnKey];
      }
    }
  };

  return <GenericTable config={timelineConfig} url={url} tags={tags} />;
};

export default TimelinesTable;
