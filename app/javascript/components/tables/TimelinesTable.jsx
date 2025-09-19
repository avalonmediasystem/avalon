import React from 'react';
import GenericTable from './GenericTable';

const TimelinesTable = ({ url, tags }) => {
  const timelineConfig = {
    // Table metadata
    tableType: 'timeline',
    containerClass: 'timeline-table-container',
    testId: 'timeline-table',
    hasTagFilter: true,

    // Table sorting and filtering keys from parsed data
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
      // Extract timeline id, tooltip, and name from link HTML
      const timelineIdMatch = row[0].match(/\/timelines\/(\d+)/);
      const toolTipMatch = row[0].match(/title="([^"]*)"/);
      const titleMatch = row[0].match(/>([^<]*)<\/a>/);

      // Extract clean visibility text from HTML for sorting
      const visibilityText = row[2].replace(/<[^>]*>/g, '').trim();

      // Regex to extract time and text from last updated field
      const regex = /<span[^>]*title=['"]([^'"]*?)['"][^>]*>([^<]*)<\/span>/;
      const updatedAtMatch = row[3].match(regex);
      const updatedAgo = updatedAtMatch ? updatedAtMatch[2] : '';
      // Ideally this would not resolve to the else condition
      const updatedAtTime = updatedAtMatch ? new Date(updatedAtMatch[1]) : new Date.now();

      return {
        id: timelineIdMatch ? timelineIdMatch[1] : index,
        title: titleMatch ? titleMatch[1] : '',
        titleTooltip: toolTipMatch ? toolTipMatch[1] : '',
        titleHtml: row[0],
        description: row[1],
        visibility: visibilityText,
        visibilityHtml: row[2],
        updated_at: updatedAtTime,
        updatedAgo: updatedAgo,
        updatedHtml: row[3],
        tags: row[4],
        actionsHtml: row[5]
      };
    },

    // Cell rendering function - how to display each cell type
    renderCell: (item, columnKey) => {
      switch (columnKey) {
        case 'title':
          return (
            <div dangerouslySetInnerHTML={{ __html: item.titleHtml }} />
          );
        case 'description':
          return item.description;
        case 'visibility':
          return <span dangerouslySetInnerHTML={{ __html: item.visibilityHtml }} />;
        case 'updated_at':
          return (
            <div dangerouslySetInnerHTML={{ __html: item.updatedHtml }} />
          );
        case 'tags':
          return item.tags;
        case 'actions':
          return (
            <div
              className="text-end"
              dangerouslySetInnerHTML={{ __html: item.actionsHtml }}
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
