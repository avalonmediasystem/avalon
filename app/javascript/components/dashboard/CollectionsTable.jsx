/*
 * Copyright 2011-2026, The Trustees of Indiana University and Northwestern
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

import GenericTable from '../tables/GenericTable';

/**
 * Render a table displaying all collection for the admin dashboard.
 * @param {Object} props
 * @param {Array}  props.data array of collection objects from the dashboard JSON endpoint
 * @param {String} props.createPath create new collection end-point
 * @param {Object} props.helpers shared helpers for common utilities in dashboard tables
 */
const CollectionsTable = ({ data, createPath, helpers }) => {
  const { truncateDescription, DashboardActionButtons } = helpers;
  const collectionConfig = {
    // Table metadata
    tableTitle: 'My Collections',
    tableType: 'collection',
    containerClass: 'dashboard-table-container',
    testId: 'collection-table',
    hasTagFilter: false,
    isDashboardTable: true,

    // Table column sorting and filtering config from parsed data
    initialSort: { columnKey: 'name', dataType: 'string', direction: 'asc' },
    searchableFields: ['name', 'unit', 'description'],
    searchPlaceholder: 'Search collections by name or unit...',

    // Table pagination customization
    initPageSize: 10,
    pageSizeOptions: [10, 25, 50, 100],
    storageKey: 'collectionTablePageSize',

    // Table create button
    createButton: { btnClass: 'btn-outline', createPath },

    // Column definitions
    columns: [
      { key: 'name', label: 'Name', sortable: true, dataType: 'string', width: '22%' },
      { key: 'items', label: 'Items', sortable: true, dataType: 'number', width: '12%' },
      { key: 'unit', label: 'Unit', sortable: true, dataType: 'string', width: '18%' },
      { key: 'description', label: 'Description', sortable: false, width: '40%' },
      { key: 'actions', label: '', sortable: false, width: '8%' },
    ],

    // Parsing function to extract data from back-end
    parseDataRow: (row) => ({
      id: row.id,
      name: row.name || '',
      unit: row.unit || '',
      collection_url: `/admin/collections/${row.id}`,
      edit_url: ``,
      // Collection remove_url = '' if the user doesn't have permission to destroy it
      remove_url: row.remove_url || '',
      search_url: `/catalog?f[collection_ssim][]=${encodeURIComponent(row.name || '')}`,
      unpublished_url: `/catalog?f[collection_ssim][]=${encodeURIComponent(row.name || '')}&f[workflow_published_sim][]=Unpublished`,
      items: row.object_count?.total || 0,
      unpublished_items: row.object_count?.unpublished || 0,
      description: row.description || '',
    }),

    // Cell rendering function for each column
    renderCell: (item, columnKey) => {
      switch (columnKey) {
        case 'name':
          return (
            <a href={item.collection_url} className="fw-bold text-dark" data-testid="collection-name-table">
              {item.name}
            </a>
          );
        case 'items':
          return (
            <div>
              <a href={item.search_url} className="fw-bold text-dark">
                {item.items} {item.items === 1 ? 'item' : 'items'}
              </a>
              {item.unpublished_items > 0 && (
                <div>
                  <a href={item.unpublished_url} className="dashboard-unpublished-link">
                    {item.unpublished_items} UNPUBLISHED
                  </a>
                </div>
              )}
            </div>
          );
        case 'unit':
          return item.unit
            ? <span className="dashboard-unit-badge">{item.unit}</span>
            : null;
        case 'description':
          return (
            <span className="text-muted">
              {truncateDescription(item.description)}
            </span>
          );
        case 'actions':
          return (
            <DashboardActionButtons
              editUrl={item.edit_url}
              removeUrl={item.remove_url}
              editTitle="Edit collection"
              deleteTitle="Delete collection"
              deleteTestId="collection-delete-collection-btn"
            />
          );
        default:
          return item[columnKey];
      }
    },
  };

  return <GenericTable config={collectionConfig} data={data} />;
};

export default CollectionsTable;
