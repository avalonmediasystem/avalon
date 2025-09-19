import React from 'react';
import GenericTable from './GenericTable';

const PlaylistsTable = ({ url, tags }) => {
  const playlistConfig = {
    // Table metadata
    tableType: 'playlist',
    containerClass: 'playlist-table-container',
    testId: 'playlist-table',
    hasTagFilter: true,

    // Table sorting and filtering keys from parsed data
    initialSort: { columnKey: 'title' },
    searchableFields: ['title'],

    // Column definitions
    columns: [
      { key: 'title', label: 'Name', sortable: true, dataType: 'string', width: '15%' },
      { key: 'size', label: 'Size', sortable: true, dataType: 'number', width: '8%' },
      { key: 'visibility', label: 'Visibility', sortable: true, dataType: 'string', width: '12%' },
      { key: 'created_at', label: 'Created', sortable: true, dataType: 'date', width: '15%' },
      { key: 'updated_at', label: 'Updated', sortable: true, dataType: 'date', width: '10%' },
      { key: 'tags', label: 'Tags', sortable: true, dataType: 'string', width: '15%' },
      { key: 'actions', label: 'Actions', sortable: false, width: '25%' },
    ],

    // Data parsing function to extract data from Rails API response
    parseDataRow: (row, index) => {
      // Extract playlist id, tooltip, and name from link HTML
      const playlistIdMatch = row[0].match(/\/playlists\/(\d+)/);
      const toolTipMatch = row[0].match(/title="([^"]*)"/);
      const titleMatch = row[0].match(/>([^<]*)<\/a>/);

      // Extract clean visibility text from HTML for sorting
      const visibilityText = row[2].replace(/<[^>]*>/g, '').trim();

      // Regex to extract time and text from created and updated fields
      const regex = /<span[^>]*title=['"]([^'"]*?)['"][^>]*>([^<]*)<\/span>/;

      const createdAtMatch = row[3].match(regex);
      const createdAgo = createdAtMatch ? createdAtMatch[2] : '';
      // Ideally this would not resolve to the else condition
      const createdAtTime = createdAtMatch ? new Date(createdAtMatch[1]) : new Date.now();

      const updatedAtMatch = row[4].match(regex);
      const updatedAgo = updatedAtMatch ? updatedAtMatch[2] : '';
      // Ideally this would not resolve to the else condition
      const updatedAtTime = updatedAtMatch ? new Date(updatedAtMatch[1]) : new Date.now();

      return {
        id: playlistIdMatch ? playlistIdMatch[1] : index,
        title: titleMatch ? titleMatch[1] : '',
        titleTooltip: toolTipMatch ? toolTipMatch[1] : '',
        titleHtml: row[0],
        size: parseInt(row[1].split(' ')[0]) || 0,
        sizeText: row[1],
        visibility: visibilityText,
        visibilityHtml: row[2],
        created_at: createdAtTime,
        createdAgo: createdAgo,
        createdHtml: row[3],
        updated_at: updatedAtTime,
        updatedAgo: updatedAgo,
        updatedHtml: row[4],
        tags: row[5],
        actionsHtml: row[6]
      };
    },

    // Cell rendering function - how to display each cell type
    renderCell: (item, columnKey) => {
      switch (columnKey) {
        case 'title':
          return (
            <div dangerouslySetInnerHTML={{ __html: item.titleHtml }} />
          );
        case 'size':
          return item.sizeText;
        case 'visibility':
          return <span dangerouslySetInnerHTML={{ __html: item.visibilityHtml }} />;
        case 'created_at':
          return (
            <div dangerouslySetInnerHTML={{ __html: item.createdHtml }} />
          );
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

  return <GenericTable config={playlistConfig} url={url} tags={tags} />;
};

export default PlaylistsTable;
