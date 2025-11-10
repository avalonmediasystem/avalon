/*
 * Copyright 2011-2024, The Trustees of Indiana University and Northwestern
 *   University.  Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed
 *   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 *   CONDITIONS OF ANY KIND, either express or implied. See the License for the
 *   specific language governing permissions and limitations under the License.
 * ---  END LICENSE_HEADER BLOCK  ---
*/

import GenericTable from './GenericTable';

/**
 * Render a table displaying playlists of the current user.
 * @param {Object} props
 * @param {String} props.url API endpoint URL for fetching playlists data
 * @param {Array} props.tags array of available tags for filtering 
 */
const PlaylistsTable = ({ url, tags }) => {
  const playlistConfig = {
    // Table metadata
    tableType: 'playlist',
    containerClass: 'playlist-table-container',
    testId: 'playlist-table',
    hasTagFilter: true,

    // Table sorting and filtering keys from parsed data (keys match column keys and parsed data keys)
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
      const parser = new DOMParser();
      // Extract playlist id and name from title link HTML
      const titleDoc = parser.parseFromString(row[0], 'text/html').querySelector('a');
      const titleLink = titleDoc.getAttribute('href');

      // Extract visibility text from HTML for sorting
      const visibilityDoc = parser.parseFromString(row[2], 'text/html').querySelector('span');

      // Extract and parse created and last updated datetime into Date object for sorting
      const createdAtDoc = parser.parseFromString(row[3], 'text/html').querySelector('span');
      const createdAtTime = createdAtDoc.getAttribute('title');

      const updatedAtDoc = parser.parseFromString(row[4], 'text/html').querySelector('span');
      const updatedAtTime = updatedAtDoc.getAttribute('title');

      return {
        id: titleLink ? titleLink.split('/').pop() : index,
        title_html: row[0], title: titleDoc ? titleDoc.textContent : '',
        size: parseInt(row[1].split(' ')[0]) || 0, size_text: row[1],
        visibility: visibilityDoc ? visibilityDoc.textContent : '', visibility_html: row[2],
        created_at: new Date(createdAtTime), created_html: row[3],
        updated_at: new Date(updatedAtTime), updated_html: row[4],
        tags: row[5], actions_html: row[6]
      };
    },

    // Cell rendering function for each column key
    renderCell: (item, columnKey) => {
      switch (columnKey) {
        case 'title':
          return (
            <div dangerouslySetInnerHTML={{ __html: item.title_html }} />
          );
        case 'size':
          return item.size_text;
        case 'visibility':
          return <span dangerouslySetInnerHTML={{ __html: item.visibility_html }} />;
        case 'created_at':
          return (
            <div dangerouslySetInnerHTML={{ __html: item.created_html }} />
          );
        case 'updated_at':
          return (
            <div dangerouslySetInnerHTML={{ __html: item.updated_html }} />
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

  return <GenericTable config={playlistConfig} url={url} tags={tags} />;
};

export default PlaylistsTable;
