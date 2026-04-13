/*
 * Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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
 */
const CollectionsTable = ({ data }) => {
  const collectionConfig = {
    tableType: 'collection',
    containerClass: 'dashboard-table-container',
    testId: 'collection-table',
    hasTagFilter: false,
    initialSort: { columnKey: 'name', dataType: 'string', direction: 'asc' },
    initPageSize: 5,
    pageSizeOptions: [5, 10, 25, 50],
    searchableFields: ['name', 'unit', 'description'],
    searchPlaceholder: 'Search collections by name or unit...',
    tableStyle: {},
    columns: [
      { key: 'name', label: 'Name', sortable: true, dataType: 'string', width: '22%' },
      { key: 'items', label: 'Items', sortable: true, dataType: 'number', width: '12%' },
      { key: 'unit', label: 'Unit', sortable: true, dataType: 'string', width: '18%' },
      { key: 'description', label: 'Description', sortable: false, width: '40%' },
      { key: 'actions', label: '', sortable: false, width: '8%' },
    ],

    parseDataRow: (row) => ({
      id: row.id,
      name: row.name || '',
      unit: row.unit || '',
      collection_url: `/collections/${row.id}`,
      edit_url: `/admin/collections/${row.id}`,
      remove_url: `/admin/collections/${row.id}/remove`,
      search_url: `/catalog?f[collection_ssim][]=${encodeURIComponent(row.name || '')}`,
      unpublished_url: `/catalog?f[collection_ssim][]=${encodeURIComponent(row.name || '')}&f[workflow_published_sim][]=Unpublished`,
      total_items: row.object_count?.total || 0,
      unpublished_items: row.object_count?.unpublished || 0,
      description: row.description || '',
    }),

    renderCell: (item, columnKey) => {
      switch (columnKey) {
        case 'name':
          return (
            <a href={item.collection_url} className="fw-bold text-decoration-none text-dark">
              {item.name}
            </a>
          );
        case 'items':
          return (
            <div>
              <a href={item.search_url} className="fw-bold text-decoration-none text-dark">
                {item.total_items} items
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
              {item.description ? item.description.substring(0, 120) + (item.description.length > 120 ? '…' : '') : ''}
            </span>
          );
        case 'actions':
          return (
            <div className="dashboard-action-icons">
              <a href={item.edit_url} className="dashboard-action-edit btn btn-outline" title="Edit collection">
                <i className="fa-regular fa-pen-to-square" />
              </a>
              <a href={item.remove_url} className="dashboard-action-delete btn btn-danger" title="Delete collection">
                <i className="fa-regular fa-trash-can" />
              </a>
            </div>
          );
        default:
          return item[columnKey];
      }
    },
  };

  return <GenericTable config={collectionConfig} data={data} />;
};

export default CollectionsTable;
