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

import { useEffect, useMemo } from 'react';
import useTableData from './hooks/useTableData';
import useTableSortingAndFiltering from './hooks/useTableSortingAndFiltering';
import useTablePagination from './hooks/useTablePagination';

const GenericTable = ({ config, url, data, tags = [], httpMethod = 'POST' }) => {
  const {
    columns: rawColumns,
    containerClass,
    displayReturnedItemsHTML = null,
    hasTagFilter,
    initialSort,
    initPageSize = 10,
    onDataParsed = null,
    pageSizeOptions = [10, 25, 50, 100],
    parseDataRow,
    renderCell,
    searchableFields = ['title'],
    searchPlaceholder = '',
    tableStyle = { minWidth: '1024px' },
    tableType,
    testId,
    storageKey = null,
    isDashboardTable = false,
    tableTitle = '',
    createButton = { btnClass: '', createPath: '' },
  } = config;

  // Filter out any false/undefined entries from conditional column definitions
  const columns = rawColumns.filter(Boolean);

  // Read persisted page size from localStorage or default to initPageSize from config
  const currentPageSize = storageKey
    ? (Number(localStorage.getItem(storageKey)) || initPageSize)
    : initPageSize;

  /**
   * Two-phase hook initialization: React requires hooks to be called unconditionally and in the
   * same order on every render, so both hook pairs must be called before 'useTableData' returns data.
   * Phase 1: empty-state instances to provide required function references to 'useTableData' hook
   */
  const pagination = useTablePagination({ initPageSize: currentPageSize });
  const sorting = useTableSortingAndFiltering({ columns, dataState: {}, initialSort, pagination, searchableFields });

  // Read and parse data from the server response or data prop (in dashboard)
  let dataState = useTableData(
    { url, data, parseDataRow, pagination: pagination.pagination, sortRows: sorting.sortRows, initialSort, httpMethod }
  );
  const { dataRows, rowsToShow, loading, totalRowCount, filteredRowCount, setRowsToShow, sortedRows } = dataState;

  /* Phase 2: data-aware instances to retrieve actual data and drive all UI interactions */
  const paginationWithData = useTablePagination({ initPageSize: currentPageSize, sortedRows, setRowsToShow, filteredRowCount });
  const sortingWithData = useTableSortingAndFiltering({ columns, dataState, initialSort, pagination: paginationWithData, searchableFields });

  const {
    pagination: paginationState,
    totalPages,
    currentPage,
    handlePageChange,
    updatePageSize,
    getPaginationPages,
  } = paginationWithData;

  const handlePageSizeChange = (newSize) => {
    // Persist selected page size for dashboard tables in localStorage
    if (storageKey) localStorage.setItem(storageKey, newSize);
    updatePageSize(newSize);
  };

  const { handleSort, getSortIcon, searchFilter, tagFilter, handleSearch, handleTagFilter } = sortingWithData;

  /**
   * Call onDataParsed callback (if provided) when data is updated. This helps to update the table
   * when data is changed outside of the table (e.g. progress updates in encoding jobs table).
   */
  useEffect(() => {
    if (onDataParsed && dataRows.length > 0) {
      onDataParsed(dataRows);
    }
  }, [dataRows, onDataParsed]);

  /**
   * Add event listeners for post-load events
   */
  useEffect(() => {
    if (!loading && rowsToShow.length > 0) {
      // Hide any active popovers
      document.querySelectorAll('.popover.show').forEach(popover => {
        popover.style.display = 'none';
      });

      // Apply button confirmation if function exists
      if (window.apply_button_confirmation) {
        window.apply_button_confirmation();
      }

      // Add type-specific button events
      if (tableType === 'playlist') {
        // Add copy playlist button events if function exists
        if (window.add_copy_playlist_button_event) {
          window.add_copy_playlist_button_event();
        }
      } else if (tableType === 'timeline') {
        // Add copy timeline button event if function exists
        if (window.add_copy_button_event) {
          window.add_copy_button_event();
        }
      }
    }
  }, [loading, rowsToShow, tableType, url]);

  const objectTypeString = useMemo(() => {
    const cleanedTableType = tableType.replaceAll('_', ' ');
    return filteredRowCount === 1 ? `${cleanedTableType}` : `${cleanedTableType}s`;
  }, [filteredRowCount, tableType]);

  /**
   * Build search and filter for the header of the table
   */
  const searchAndFilter = useMemo(() => {
    return (
      <>
        {displayReturnedItemsHTML}
        <div className={`d-flex justify-content-between align-items-center flex-sm-wrap${isDashboardTable ? ' p-4' : ''}`}>
          <div className="d-flex justify-content-between page-title-wrapper mb-3">
            <h1 className="page-title mb-0 section-title">{tableTitle}</h1>
          </div>
          <div className='d-flex justify-content-end gap-2 flex-sm-wrap'>
            <div className="d-flex align-items-center">
              <label htmlFor={`search-${tableType}`} className="me-2 mb-0">Search:</label>
              <input
                id={`search-${tableType}`}
                type="text"
                value={searchFilter}
                className="form-control"
                placeholder={searchPlaceholder}
                data-testid={`${testId}-search-field`}
                onChange={handleSearch}
              />
            </div>
            {hasTagFilter && (<div className="d-flex align-items-center">
              <label htmlFor="tag-filter-select" className="me-2 mb-0">Filter:</label>
              <select
                id="tag-filter-select"
                className="form-select tag-filter"
                value={tagFilter}
                onChange={handleTagFilter}
              >
                <option value=""></option>
                {Array.isArray(tags) && tags.length != 0 && tags.map(tag => (
                  <option key={tag} value={tag}>{tag}</option>
                ))}
              </select>
            </div>)}
          </div>
          {createButton.createPath != '' && (
            <a href={createButton.createPath}>
              <span className={`btn ${createButton.btnClass} btn-large section-create-button`} data-testid={`${tableType}-create-${tableType}-button`}>
                <i className="fa fa-plus" aria-hidden="true"></i> {`Create ${tableType}`}
              </span>
            </a>
          )}
        </div>
      </>
    );
  }, [tags, filteredRowCount, paginationState, totalRowCount,
    tagFilter, handleSearch, handleTagFilter, rowsToShow, loading]);

  return (
    <div key={`${tableType}-table`} className={containerClass}>
      {searchAndFilter}
      {loading ?
        (<div className="text-center py-3">
          <div className="spinner-border" role="status">
            <span className="visually-hidden">Loading...</span>
          </div>
        </div>)
        :
        (<>
          <div className="table-responsive">
            {/* min-width is set to an arbitrary value of 1024px to get the table to not shrink for smaller view-ports */}
            <table className={`table generic-table${isDashboardTable ? '' : ' table-striped'}`} style={tableStyle}>
              <thead data-testid={`${testId}-head`}>
                <tr>
                  {columns.map((column, index) => (
                    column.key != 'actions'
                      ? (<th
                        key={column.key}
                        className={`${column.sortable ? 'user-select-none' : ''}`}
                        style={{ cursor: column.sortable ? 'pointer' : 'default', width: column.width ? column.width : 'auto' }}
                        onClick={() => handleSort(index)}
                        colSpan={1}
                        rowSpan={1}
                        scope="col"
                      >
                        {column.label}
                        {getSortIcon(index)}
                      </th>)
                      : <td key={column.key} className="invisible-actions-header"></td>
                  ))}
                </tr>
              </thead>
              <tbody data-testid={`${testId}-body`}>
                {rowsToShow.length === 0 && !loading ? (
                  <tr>
                    <td colSpan={columns.length} className="text-center py-2">
                      No matching records found
                    </td>
                  </tr>
                ) : (
                  rowsToShow.map((item, index) => (
                    <tr key={item.id || index}>
                      {columns.map((column) => (
                        <td key={column.key}>
                          {renderCell(item, column.key)}
                        </td>
                      ))}
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
          <div className={`d-flex justify-content-between${isDashboardTable ? ' p-4' : ''}`}>
            <div>
              <label className='d-flex align-items-center text-sm text-muted'>
                Show
                <select
                  className="form-select mx-2 fw-bold"
                  value={paginationState.pageSize}
                  onChange={e => handlePageSizeChange(Number(e.target.value))}
                >
                  {pageSizeOptions.map(size => (
                    <option key={size} value={size}>{size}</option>
                  ))}
                </select>
                entries
              </label>
            </div>
            <div className="d-flex justify-content-between align-items-center gap-3">
              <div className="text-muted">
                {(rowsToShow?.length === 0 && !loading)
                  ? <span>Showing<b >0</b> - <b>0</b> of <b>0</b> {objectTypeString}</span>
                  : <span>Showing
                    <b> {paginationState.pageIndex * paginationState.pageSize + 1} </b> -
                    <b> {Math.min((paginationState.pageIndex + 1) * paginationState.pageSize, filteredRowCount)}</b> of
                    <b> {filteredRowCount}</b>  {objectTypeString}
                  </span>
                }
                {filteredRowCount < totalRowCount && <span> (filtered from <b>{totalRowCount}</b> total {objectTypeString})</span>}
              </div>
              <div className="d-flex align-items-center gap-3">
                <nav>
                  <ul className="pagination flex-nowrap mb-0">
                    <li className={`page-item ${paginationState.pageIndex === 0 ? 'disabled' : ''}`}>
                      <button
                        className="page-link"
                        onClick={() => handlePageChange(paginationState.pageIndex - 1)}
                        disabled={paginationState.pageIndex === 0}
                      >
                        Previous
                      </button>
                    </li>
                    {getPaginationPages().map((page, idx) =>
                      page === '...' ? (
                        <li key={`ellipsis-${idx}`} className="page-item disabled">
                          <span className="page-link">...</span>
                        </li>
                      ) : (
                        <li key={page} className={`page-item ${currentPage === page ? 'active' : ''}`}
                        >
                          <button
                            className="page-link"
                            onClick={() => handlePageChange(page - 1)}
                            disabled={currentPage === page}>{page}</button>
                        </li>
                      )
                    )}
                    <li className={`page-item ${paginationState.pageIndex >= totalPages - 1 ? 'disabled' : ''}`}>
                      <button
                        className="page-link"
                        onClick={() => handlePageChange(paginationState.pageIndex + 1)}
                        disabled={paginationState.pageIndex >= totalPages - 1}>Next</button>
                    </li>
                  </ul>
                </nav>
              </div>
            </div>
          </div>
        </>)
      }
    </div>
  );
};

export default GenericTable;
