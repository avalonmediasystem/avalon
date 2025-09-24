import React from 'react';
import GenericTable from './GenericTable';

const UsersTable = ({ url, hasProvider = false }) => {
  const usersConfig = {
    // Table metadata
    tableType: 'playlist',
    containerClass: 'playlist-table-container',
    testId: 'playlist-table',
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
      const parser = new DOMParser();
      const userDoc = parser.parseFromString(row[0], 'text/html');
      const userIdRegex = /\/users\/(\d+)\//;
      const userIdMatch = row[0].match(userIdRegex);

      const emailDoc = parser.parseFromString(row[1], 'text/html');

      const rolesDoc = parser.parseFromString(row[2], 'text/html');
      const rolesLi = rolesDoc.querySelectorAll('li');

      const lastAccessDateDoc = parser.parseFromString(row[3], 'text/html');
      const lastAccessDateAttr = lastAccessDateDoc.querySelector('relative-time').getAttribute('datetime');

      let userData = {
        id: userIdMatch ? userIdMatch[1] : index,
        user_html: row[0], user: userDoc ? userDoc.querySelector('a').textContent : '',
        email_html: row[1], email: emailDoc ? emailDoc.querySelector('a').textContent : '',
        roles_html: row[2], roles: rolesLi?.length > 0 ? rolesLi.forEach((r) => { return r.textContent; }) : [],
        lastaccess_html: row[3], last_access: lastAccessDateAttr ? new Date(lastAccessDateAttr) : new Date.now(),
        status: row[4], actions_html: row[hasProvider ? 6 : 5]
      };

      // Add provider column data if present
      if (hasProvider) { userData.provider = row[5]; }

      return userData;
    },

    // Cell rendering function for each column key
    renderCell: (item, columnKey) => {
      switch (columnKey) {
        case 'user':
          return <div dangerouslySetInnerHTML={{ __html: item.user_html }} />;
        case 'email':
          return <div dangerouslySetInnerHTML={{ __html: item.email_html }} />;
        case 'roles':
          return <div dangerouslySetInnerHTML={{ __html: item.roles_html }} />;
        case 'last_access':
          return <div dangerouslySetInnerHTML={{ __html: item.lastaccess_html }} />;
        case 'status':
          return item.status;
        case 'provider':
          return item.provider;
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

  return <GenericTable config={usersConfig} url={url} />;
};

export default UsersTable;
