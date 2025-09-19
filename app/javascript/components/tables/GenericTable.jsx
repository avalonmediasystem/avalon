import React, { useEffect, useMemo } from 'react';
import useTableData from './hooks/useTableData';
import useTableSortingAndFiltering from './hooks/useTableSortingAndFiltering';
import useTablePagination from './hooks/useTablePagination';

const PAGE_SIZES = [10, 25, 50, 100];

const GenericTable = ({ config, url, tags = [], httpMethod = 'POST' }) => {
  const {
    tableType,
    hasTagFilter,
    initialSort,
    containerClass,
    testId,
    columns,
    parseDataRow,
    renderCell,
    displayReturnedItemsHTML = null,
    searchableFields = ['title']
  } = config;

  // Initial setup of pagination and sorting
  const pagination = useTablePagination({});
  const sorting = useTableSortingAndFiltering({ columns, dataState: {}, initialSort, pagination, searchableFields });
  // Read and parse data from the server response
  const dataState = useTableData(
    url, parseDataRow, pagination.pagination, sorting.sortRows, initialSort, httpMethod
  );

  // Update pagination, sorting and filtering from the parsed data
  const paginationWithData = useTablePagination(dataState);
  const sortingWithData = useTableSortingAndFiltering({ columns, dataState, initialSort, pagination: paginationWithData, searchableFields });

  const { rowsToShow, loading, totalRowCount, filteredRowCount } = dataState;
  const {
    pagination: paginationState,
    totalPages,
    currentPage,
    handlePageChange,
    handlePageSizeChange,
    getPaginationPages,
  } = paginationWithData;
  const { handleSort, getSortIcon,
    searchFilter, tagFilter, handleSearch, handleTagFilter } = sortingWithData;

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

  /**
   * Build search and filter for the header of the table
   */
  const searchAndFilter = useMemo(() => {
    return (
      <>
        {displayReturnedItemsHTML}
        <div className="d-flex justify-content-between align-items-center mb-3 flex-sm-wrap">
          <div>
            {(rowsToShow?.length === 0 && !loading)
              ? 'Showing 0 to 0 of 0 entries'
              : `Showing ${paginationState.pageIndex * paginationState.pageSize + 1} to${' '}
          ${Math.min((paginationState.pageIndex + 1) * paginationState.pageSize, filteredRowCount)} of${' '}
          ${filteredRowCount} entries`}
            {filteredRowCount < totalRowCount && ` (filtered from ${totalRowCount} total entries)`}
          </div>
          <div className='d-flex justify-content-end gap-2 flex-sm-wrap'>
            <div className="d-flex align-items-center">
              <label htmlFor={`search-${tableType}`} className="me-2 mb-0">Search:</label>
              <input
                id={`search-${tableType}`}
                type="text"
                className="form-control"
                value={searchFilter}
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
        </div>
      </>
    );
  }, [tags, filteredRowCount, paginationState, totalRowCount, searchFilter,
    tagFilter, handleSearch, handleTagFilter, rowsToShow, loading]);

  return (
    <div className={containerClass}>
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
            <table className="table table-striped generic-table" style={{ minWidth: '1024px' }}>
              <thead data-testid={`${testId}-head`}>
                <tr>
                  {columns.map((column, index) => (
                    <th
                      key={column.key}
                      className={`${column.sortable ? 'user-select-none' : ''} ${column.key === 'actions' ? 'text-end' : ''}`}
                      style={{ cursor: column.sortable ? 'pointer' : 'default', width: column.width ? column.width : 'auto' }}
                      onClick={() => handleSort(index)}
                      colSpan={1}
                      rowSpan={1}
                    >
                      {column.label}
                      {getSortIcon(index)}
                    </th>
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
          <div className="d-flex justify-content-between">
            <div>
              <label className='d-flex align-items-center'>
                Show
                <select
                  className="form-select mx-2"
                  value={paginationState.pageSize}
                  onChange={e => handlePageSizeChange(Number(e.target.value))}
                >
                  {PAGE_SIZES.map(size => (
                    <option key={size} value={size}>{size}</option>
                  ))}
                </select>
                entries
              </label>
            </div>
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
        </>)
      }
    </div>
  );
};

export default GenericTable;
