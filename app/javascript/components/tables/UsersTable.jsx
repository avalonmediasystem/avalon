import React from 'react';
import GenericTable from './GenericTable';

const UsersTable = ({ url, hasProvider = false }) => {
  const usersConfig = {
    // Table metadata
    tableType: 'playlist',
    containerClass: 'playlist-table-container',
    testId: 'playlist-table',
    hasTagFilter: false,

    // Table sorting and filtering keys from parsed data
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

      let result = {
        id: userIdMatch ? userIdMatch[1] : index,
        userHtml: row[0], user: userDoc ? userDoc.querySelector('a').textContent : '',
        emailHtml: row[1], email: emailDoc ? emailDoc.querySelector('a').textContent : '',
        rolesHtml: row[2], roles: rolesLi?.length > 0 ? rolesLi.forEach((r) => { return r.textContent; }) : [],
        lastAccessHtml: row[3], lastAccess: lastAccessDateAttr ? new Date(lastAccessDateAttr) : new Date.now(),
        statusText: row[4], actionsHtml: row[hasProvider ? 6 : 5]
      };

      console.log(row, hasProvider);
      if (hasProvider) { result.provider = row[5]; }

      return result;
    },

    // Cell rendering function - how to display each cell type
    renderCell: (item, columnKey) => {
      switch (columnKey) {
        case 'user':
          return <div dangerouslySetInnerHTML={{ __html: item.userHtml }} />;
        case 'email':
          return <div dangerouslySetInnerHTML={{ __html: item.emailHtml }} />;
        case 'roles':
          return <div dangerouslySetInnerHTML={{ __html: item.rolesHtml }} />;
        case 'last_access':
          return <div dangerouslySetInnerHTML={{ __html: item.lastAccessHtml }} />;
        case 'status':
          return item.statusText;
        case 'provider':
          return item.provider;
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

  return <GenericTable config={usersConfig} url={url} />;
};

export default UsersTable;
