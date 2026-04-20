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
 * Render a table displaying all units for the admin dashboard.
 * @param {Object} props
 * @param {Array}  props.data array of unit objects from the dashboard JSON endpoint
 * @param {Object} props.helpers shared helpers for common utilities in dashboard tables
 */
const UnitsTable = ({ data, helpers }) => {
  const { truncateDescription, DashboardActionButtons } = helpers;
  const unitConfig = {
    // Table metadata
    tableType: 'unit',
    isDashboardTable: true,
    containerClass: 'dashboard-table-container',
    testId: 'unit-table',
    hasTagFilter: false,

    // Table column sorting and filtering config from parsed data
    initialSort: { columnKey: 'name', dataType: 'string', direction: 'asc' },
    searchableFields: ['name', 'description'],
    searchPlaceholder: 'Search units by name...',

    // Table pagination customization
    initPageSize: 5,
    pageSizeOptions: [5, 10, 25, 50],

    // Column definitions
    columns: [
      { key: 'name', label: 'Name', sortable: true, dataType: 'string', width: '20%' },
      { key: 'items', label: 'Items', sortable: true, dataType: 'number', width: '12%' },
      { key: 'administrators', label: 'Unit Administrators', sortable: false, width: '23%' },
      { key: 'description', label: 'Description', sortable: false, width: '35%' },
      { key: 'actions', label: '', sortable: false, width: '10%' },
    ],

    // View all link for units
    viewAllUrl: '/admin/units',

    // Parsing function to extract data from back-end
    parseDataRow: (row) => ({
      id: row.id,
      name: row.name || '',
      search_url: `/catalog?f[unit_ssim][]=${encodeURIComponent(row.name || '')}`,
      unit_url: `/units/${row.id}`,
      edit_url: `/admin/units/${row.id}`,
      // Unit remove_url = '' if the user doesn't have permission to destroy it
      remove_url: row.remove_url || '',
      items: row.object_count?.total || 0,
      administrators: row.roles?.unit_admins?.length || 0,
      description: row.description || '',
    }),

    // Cell rendering function for each column
    renderCell: (item, columnKey) => {
      switch (columnKey) {
        case 'name':
          return (
            <a href={item.unit_url} className="fw-bold text-decoration-none text-dark" data-testid="unit-name-table">
              {item.name}
            </a>
          );
        case 'items':
          return (
            <a href={item.search_url} className="text-decoration-none" data-testid="unit-collections-count">
              {item.items} {item.items === 1 ? 'collection' : 'collections'}
            </a>
          );
        case 'administrators':
          return (<span className="text-muted">
            {item.administrators}  {item.administrators === 1 ? 'administrator' : 'administrators'}
          </span>);
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
              editTitle="Edit unit"
              deleteTitle="Delete unit"
              deleteTestId="unit-delete-unit-btn"
            />
          );
        default:
          return item[columnKey];
      }
    },
  };

  return <GenericTable config={unitConfig} data={data} />;
};

export default UnitsTable;
