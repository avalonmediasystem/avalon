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

import GenericTable from './GenericTable';

const UsersTable = ({ url, hasProvider = false }) => {
  const usersConfig = {
    // Table metadata
    tableType: 'user',
    containerClass: 'user-table-container',
    testId: 'user-table',
    hasTagFilter: false,

    // Table sorting and filtering keys from parsed data (keys match column keys and parsed data keys)
    initialSort: { columnKey: 'user' },
    searchableFields: ['user', 'email'],

    // Column definitions
    columns: [
      { key: 'user', label: 'Username', sortable: true, dataType: 'string', width: '15%' },
      { key: 'email', label: 'Email', sortable: true, dataType: 'string', width: '20%' },
      { key: 'roles', label: 'Roles', sortable: false, width: '12%' },
      { key: 'last_access', label: 'Last access', sortable: true, dataType: 'date', width: '20%' },
      { key: 'status', label: 'Status', sortable: true, dataType: 'string', width: '10%' },
      hasProvider && { key: 'provider', label: 'Provider', sortable: true, dataType: 'string', width: '8%' },
      { key: 'actions', label: 'Action', sortable: false, width: '15%' },
    ],

    // Data parsing function to extract data from Rails API response
    parseDataRow: (row, index) => {
      let userData = {
        id: row.id,
        user: row.username || '',
        email: row.email || '',
        roles: row.roles || [],
        last_access: row.last_sign_in,
        provider: row.provider,
        status: row.status,
        paths: row.paths
      };

      return userData;
    },

    // Cell rendering function for each column key
    renderCell: (item, columnKey) => {
      switch (columnKey) {
        case 'user':
          return <a href={item.paths.edit}>{item.user}</a>;
        case 'email':
          return <a href={item.paths.edit}>{item.email}</a>;
        case 'roles':
          return(
            <ul>
              {item.roles.map((role, idx) => <li key={idx}>{role}</li>)}
            </ul>
          )
        case 'last_access':
          return(
            <relative-time datetime={item.last_access.datetime} title={item.last_access.title}>{item.last_access.label}</relative-time>
          )
        case 'status':
          return item.status;
        case 'provider':
          return item.provider;
        case 'actions':
          return (
            <div className="text-end">
              {item.provider ? (
                <span className="text-muted" title="Edit user is unavailable because this user is single sign on" data-toggle="tooltip">Edit</span>
              ) : (
                <a href={item.paths.edit}>Edit</a>
              )}
              {` | `}
              <a data-method="post" href={item.paths.impersonate}>Become</a>
              {` | `}
              <a className="btn btn-danger btn-sm action-delete" 
                 data-confirm={`Are you sure you wish to delete the user '${item.email}'? This action will also delete all playlists and timelines belonging to '${item.email}'. This action is irreversible.`}
                 data-method="delete" 
                 href={item.paths.delete}>
                Delete
              </a>
            </div>
          );
        default:
          return item[columnKey];
      }
    }
  };

  return <GenericTable config={usersConfig} url={url} />;
};

export default UsersTable;
