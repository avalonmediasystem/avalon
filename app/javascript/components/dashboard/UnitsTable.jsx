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
 * Render a table displaying all units for the admin dashboard.
 * @param {Object} props
 * @param {Array}  props.data array of unit objects from the dashboard JSON endpoint
 */
const UnitsTable = ({ data }) => {
  const unitConfig = {
    tableType: 'unit',
    containerClass: 'dashboard-table-container',
    testId: 'unit-table',
    hasTagFilter: false,
    initialSort: { columnKey: 'name', dataType: 'string', direction: 'asc' },
    searchableFields: ['name', 'description'],
    searchPlaceholder: 'Search units by name...',
    tableStyle: {},
    columns: [
      { key: 'name', label: 'Name', sortable: true, dataType: 'string', width: '25%' },
      { key: 'collections', label: 'Collections', sortable: true, dataType: 'number', width: '15%' },
      { key: 'description', label: 'Description', sortable: false, width: '50%' },
      { key: 'actions', label: '', sortable: false, width: '10%' },
    ],

    parseDataRow: (row) => ({
      id: row.id,
      name: row.name || '',
      search_url: `/catalog?f[unit_ssim][]=${encodeURIComponent(row.name || '')}`,
      unit_url: `/units/${row.id}`,
      edit_url: `/admin/units/${row.id}`,
      remove_url: `/admin/units/${row.id}/remove`,
      collections: row.object_count?.total || 0,
      description: row.description || '',
    }),

    renderCell: (item, columnKey) => {
      switch (columnKey) {
        case 'name':
          return (
            <a href={item.unit_url} className="fw-bold text-decoration-none text-dark">
              {item.name}
            </a>
          );
        case 'collections':
          return (
            <a href={item.search_url} className="text-decoration-none">
              {item.collections} {item.collections === 1 ? 'collection' : 'collections'}
            </a>
          );
        case 'description':
          return (
            <span className="text-muted">
              {item.description ? item.description.substring(0, 120) + (item.description.length > 120 ? '…' : '') : ''}
            </span>
          );
        case 'actions':
          return (
            <div className="dashboard-action-icons">
              <a href={item.edit_url} className="dashboard-action-edit btn btn-outline" title="Edit unit">
                <i className="fa-regular fa-pen-to-square" />
              </a>
              <a href={item.remove_url} className="dashboard-action-delete btn btn-danger" title="Delete unit">
                <i className="fa-regular fa-trash-can" />
              </a>
            </div>
          );
        default:
          return item[columnKey];
      }
    },
  };

  return <GenericTable config={unitConfig} data={data} />;
};

export default UnitsTable;
