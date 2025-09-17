import React, { useState, useEffect, useMemo } from 'react';

const PlaylistsTable = ({ url, tags }) => {
  const [dataRows, setDataRows] = useState([]);
  const [sortedRows, setSortedRows] = useState([]);
  const [rowsToShow, setRowsToShow] = useState(dataRows);
  const [loading, setLoading] = useState(false);
  const [pagination, setPagination] = useState({
    pageIndex: 0,
    pageSize: 5,
    pages: [],
  });
  const [sorting, setSorting] = useState({ column: 0, direction: 'asc' });
  const [titleFilter, setTitleFilter] = useState('');
  const [tagFilter, setTagFilter] = useState('');
  const [totalRowCount, setTotalRowCount] = useState(0);
  const [filteredRowCount, setFilteredRowCount] = useState(0);

  const columns = [
    { key: 'title', label: 'Name', sortable: true },
    { key: 'size', label: 'Size', sortable: true },
    { key: 'visibility', label: 'Visibility', sortable: true },
    { key: 'created_at', label: 'Created', sortable: true },
    { key: 'updated_at', label: 'Updated', sortable: true },
    { key: 'tags', label: 'Tags', sortable: true },
    { key: 'actions', label: 'Actions', sortable: false },
  ];

  const fetchData = async () => {
    setLoading(true);

    // const payload = {
    //   draw: Date.now(),
    //   start: pagination.pageIndex * pagination.pageSize,
    //   search: { value: titleFilter },
    //   order: { '0': { column: sorting.column, dir: sorting.direction } },
    //   columns: {
    //     '5': { search: { value: tagFilter } }
    //   }
    // };

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content'),
        },
        // body: JSON.stringify(payload)
      });

      const result = await response.json();

      // Parse the Rails response data
      const parsedData = result.data.map((row, index) => {
        // Extract playlist id, tooltip, and name from link HTML
        const playlistIdMatch = row[0].match(/\/playlists\/(\d+)/);
        const toolTipMatch = row[0].match(/title="([^"]*)"/);
        const titleMatch = row[0].match(/>([^<]*)<\/a>/);

        // Extract clean visibility text from HTML for sorting
        const visibilityText = row[2].replace(/<[^>]*>/g, '').trim();

        // Regex to extract time and text from created and updated fields
        const regex = /<span[^>]*title=['"]([^'"]*?)['"][^>]*>([^<]*)<\/span>/;

        const createdAtMatch = row[3].match(regex);
        const createdAgo = createdAtMatch ? createdAtMatch[2] : '';
        // Ideally this would not resolve to the else condition
        const createdAtTime = createdAtMatch ? new Date(createdAtMatch[1]) : new Date.now();

        const updatedAtMatch = row[4].match(regex);
        const updatedAgo = updatedAtMatch ? updatedAtMatch[2] : '';
        // Ideally this would not resolve to the else condition
        const updatedAtTime = updatedAtMatch ? new Date(updatedAtMatch[1]) : new Date.now();

        return {
          id: playlistIdMatch ? playlistIdMatch[1] : index,
          title: titleMatch ? titleMatch[1] : '',
          titleTooltip: toolTipMatch ? toolTipMatch[1] : '',
          titleHtml: row[0],
          size: parseInt(row[1].split(' ')[0]) || 0,
          sizeText: row[1],
          visibility: visibilityText,
          visibilityHtml: row[2],
          createdAt: createdAtTime,
          createdAgo: createdAgo,
          createdHtml: row[3],
          updatedAt: updatedAtTime,
          updatedAgo: updatedAgo,
          updatedHtml: row[4],
          tags: row[5],
          actionsHtml: row[6]
        };
      });

      setTotalRowCount(result.recordsTotal);
      setFilteredRowCount(result.recordsTotal);

      setDataRows(parsedData);

      // Sort the initial data set by 'title' from A-Z
      const sortedData = sortRows(parsedData, 'title', 'asc');
      setSortedRows(sortedData);

      // Apply initial pagination to show first page
      const { pageSize } = pagination;
      const end = Math.min(pageSize, sortedData.length);
      setRowsToShow(sortedData.slice(0, end));
    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setLoading(false);
    }
  };

  // Fetch data from the given API-endpoint on load
  useEffect(() => { fetchData(); }, []);

  /**
   * Sort rows by a given column key and direction (asc/desc)
   * @param {Array} rows 
   * @param {String} columnKey column name to be used for sorting
   * @param {String} direction sorting direction (asc/desc)
   * @returns {Array}
   */
  const sortRows = (rows, columnKey, direction) => {
    if (columnKey === 'last_updated' || columnKey === 'created_at' || columnKey === 'updated_at') {
      // Sort by actual date values from the parsed timestamps
      const sorted = [...rows].sort((a, b) => {
        const dateField = columnKey === 'created_at' ? 'createdAt' : 'updatedAt';
        const dateA = new Date(a[dateField]);
        const dateB = new Date(b[dateField]);
        return dateA - dateB;
      });
      return direction === 'asc' ? sorted : sorted.reverse();
    } else if (columnKey === 'size') {
      // Sort by size
      rows.sort((a, b) => a.size - b.size);
      const sorted = rows.sort((a, b) => a.size - b.size);
      return direction === 'asc' ? sorted : sorted.reverse();
    } else {
      // Case-insensitive sort with stable fallback
      const sorted = [...rows].sort((a, b) => {
        const aVal = (a[columnKey] || '').toString().toLowerCase();
        const bVal = (b[columnKey] || '').toString().toLowerCase();

        //  Case-insensitive comparison
        if (aVal < bVal) return -1;
        if (aVal > bVal) return 1;

        // Case-sensitive value for stable sort
        const aOriginal = (a[columnKey] || '').toString();
        const bOriginal = (b[columnKey] || '').toString();
        if (aOriginal < bOriginal) return -1;
        if (aOriginal > bOriginal) return 1;
        return 0;
      });
      return direction === 'asc' ? sorted : sorted.reverse();
    }
  };

  const handleSort = (columnIndex) => {
    if (!columns[columnIndex].sortable) return;

    const columnKey = columns[columnIndex].key;

    let sortDirection;
    if (sorting.column === columnIndex) {
      // Same column clicked - toggle direction
      sortDirection = sorting.direction === 'asc' ? 'desc' : 'asc';
    } else {
      // Different column clicked - choose appropriate default direction
      if (columnKey === 'created_at' || columnKey === 'updated_at') {
        // Date columns: start with oldest first
        sortDirection = 'asc';
      } else if (columnKey === 'size') {
        // Size column: start with smallest first
        sortDirection = 'asc';
      } else {
        // Text columns: start with A-Z
        sortDirection = 'asc';
      }
    }

    // Sort the current working dataset (sortedRows contains filtered data if filters are active)
    const sortedData = sortRows(dataRows, columnKey, sortDirection);
    setSortedRows(sortedData);

    // Apply pagination to the sorted data
    const { pageSize } = pagination;
    const start = 0; // Reset to first page when sorting
    const end = Math.min(pageSize, sortedData.length);
    setRowsToShow(sortedData.slice(start, end));

    setSorting({ column: columnIndex, direction: sortDirection });
    setPagination(prev => ({ ...prev, pageIndex: 0 }));
  };

  const handlePageChange = (newPageIndex) => {
    setPagination(prev => ({ ...prev, pageIndex: newPageIndex }));
    const { pageSize } = pagination;
    const start = newPageIndex * pageSize;
    const end = Math.min(start + pageSize, sortedRows.length);
    setRowsToShow(sortedRows.slice(start, end));
  };

  const handlePageSizeChange = (newPageSize) => {
    setRowsToShow(sortedRows.slice(0, newPageSize));
    setPagination({ pageIndex: 0, pageSize: newPageSize });
  };

  const handleSearch = (e) => {
    const filter = e.target.value;
    setTitleFilter(filter);
    filterRows(filter, tagFilter);
  };

  const handleTagFilter = (e) => {
    const filter = e.target.value;
    setTagFilter(filter);
    filterRows(titleFilter, filter);
  };

  const filterRows = (title, tag) => {
    let filtered = sortedRows;
    // Filter on search from title
    if (title.trim() !== '') {
      filtered = filtered.filter(row =>
        row.title.toLowerCase().includes(title.toLowerCase())
      );
    }

    // Filter on tag filter values
    if (tag.trim() !== '') {
      filtered = filtered.filter(row => {
        if (Array.isArray(row.tags)) {
          return row.tags.includes(tag);
        } else if (typeof row.tags === 'string') {
          // Parse comma-separated tags and check for exact match
          const tags = row.tags.split(',').map(t => t.trim());
          return tags.includes(tag);
        }
        return false;
      });
    }
    // Set filteredRowCount to be used in the text
    setFilteredRowCount(filtered?.length);

    // Apply pagination to filtered (and potentially sorted) data
    const pageSize = pagination.pageSize;
    // Reset to first page when filtering
    const start = 0;
    const end = Math.min(pageSize, filtered.length);
    setRowsToShow(filtered.slice(start, end));

    setPagination(prev => ({
      ...prev,
      pageIndex: 0,
      pages: Array.from({ length: Math.ceil(filtered?.length / prev.pageSize) }, (_, i) => i + 1)
    }));
  };

  const totalPages = useMemo(() => {
    return Math.ceil(filteredRowCount / pagination.pageSize);
  }, [pagination.pageSize, filteredRowCount]);

  const currentPage = useMemo(() => {
    return pagination.pageIndex + 1;
  }, [pagination.pageIndex]);

  const getSortIcon = (columnIndex) => {
    if (!columns[columnIndex].sortable) return null;
    if (sorting.column !== columnIndex) {
      return <span className="text-muted ms-1"><i className="fa fa-sort"></i></span>;
    }
    return (
      <span className="ms-1">
        {sorting.direction === 'asc' ? (
          <i className="fa fa-sort-up"></i>
        ) : (
          <i className="fa fa-sort-down"></i>
        )}
      </span>
    );
  };

  const renderCell = (item, columnKey) => {
    switch (columnKey) {
      case 'title':
        return (
          <div dangerouslySetInnerHTML={{ __html: item.titleHtml }} />
        );
      case 'size':
        return item.sizeText;
      case 'visibility':
        return <span dangerouslySetInnerHTML={{ __html: item.visibilityHtml }} />;
      case 'created_at':
        return (
          <div dangerouslySetInnerHTML={{ __html: item.createdHtml }} />
        );
      case 'updated_at':
        return (
          <div dangerouslySetInnerHTML={{ __html: item.updatedHtml }} />
        );
      case 'tags':
        return item.tags;
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
  };

  // Add event listeners for post-load events
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

      // Add copy playlist button events if function exists
      if (window.add_copy_playlist_button_event) {
        window.add_copy_playlist_button_event();
      }

      // // File data change handlers
      // document.querySelectorAll('.filedata').forEach(input => {
      //   input.addEventListener('change', function () {
      //     this.closest('form').submit();
      //   });
      // });
    }
  }, [loading, rowsToShow]);

  /**
   * Build pagination page numbers list based on the currentPage and totalPages
   * count
   * @returns {Object}
   */
  const getPaginationPages = () => {
    // Do not build '...' element for page counts smaller than 5
    if (totalPages <= 5) {
      return Array.from({ length: totalPages }, (_, i) => i + 1);
    }

    // Build page numbers with '...' in the middle for larger page counts
    const pages = [];
    if (currentPage <= 3) {
      pages.push(1, 2, 3, 4, '...', totalPages);
    } else if (currentPage >= totalPages - 2) {
      pages.push(1, '...', totalPages - 3, totalPages - 2, totalPages - 1, totalPages);
    } else {
      pages.push(1, '...', currentPage, currentPage + 1, '...', totalPages);
    }
    return pages;
  };

  /**
   * Build search and filter for the header of the table
   */
  const searchAndFilter = useMemo(() => {
    return (
      <div className="d-flex justify-content-between align-items-center mb-3 flex-sm-wrap">
        <div>
          {(rowsToShow?.length === 0 && !loading)
            ? 'Showing 0 to 0 of 0 entries'
            : `Showing ${pagination.pageIndex * pagination.pageSize + 1} to${' '}
          ${Math.min((pagination.pageIndex + 1) * pagination.pageSize, filteredRowCount)} of${' '}
          ${filteredRowCount} entries`}
          {filteredRowCount < totalRowCount && ` (filtered from ${totalRowCount} total entries)`}
        </div>
        <div className='d-flex justify-content-end gap-2 flex-sm-wrap'>
          <div className="d-flex align-items-center">
            <label htmlFor="search-playlist" className="me-2 mb-0">Search:</label>
            <input
              id="search-playlist"
              type="text"
              className="form-control"
              value={titleFilter}
              onChange={handleSearch}
              style={{ width: '200px' }}
            />
          </div>
          <div className="d-flex align-items-center">
            <label htmlFor="tag-filter-select" className="me-2 mb-0">Filter:</label>
            <select
              id="tag-filter-select"
              className="form-select tag-filter"
              value={tagFilter}
              onChange={handleTagFilter}
              style={{ width: '200px' }}
            >
              <option value=""></option>
              {Array.isArray(tags) && tags.length != 0 && tags.map(tag => (
                <option key={tag} value={tag}>{tag}</option>
              ))}
            </select>
          </div>
        </div>
      </div>
    );
  }, [tags, filteredRowCount, pagination, totalRowCount]);

  return (
    <div className="playlist-table-container">
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
            <table className="table table-striped">
              <thead data-testid="playlist-table-head">
                <tr>
                  {columns.map((column, index) => (
                    <th
                      key={column.key}
                      className={`${column.sortable ? 'user-select-none' : ''} ${column.key === 'actions' ? 'text-end' : ''}`}
                      style={{ cursor: column.sortable ? 'pointer' : 'default' }}
                      onClick={() => handleSort(index)}
                    >
                      {column.label}
                      {getSortIcon(index)}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody data-testid="playlist-table-body">
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
                  value={pagination.pageSize}
                  onChange={e => handlePageSizeChange(Number(e.target.value))}
                >
                  {[5, 10, 25, 50, 100].map(size => (
                    <option key={size} value={size}>{size}</option>
                  ))}
                </select>
                entries
              </label>
            </div>
            <nav>
              <ul className="pagination flex-nowrap mb-0">
                <li className={`page-item ${pagination.pageIndex === 0 ? 'disabled' : ''}`}>
                  <button
                    className="page-link"
                    onClick={() => handlePageChange(pagination.pageIndex - 1)}
                    disabled={pagination.pageIndex === 0}
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
                <li className={`page-item ${pagination.pageIndex >= totalPages - 1 ? 'disabled' : ''}`}>
                  <button
                    className="page-link"
                    onClick={() => handlePageChange(pagination.pageIndex + 1)}
                    disabled={pagination.pageIndex >= totalPages - 1}>Next</button>
                </li>
              </ul>
            </nav>
          </div>
        </>)
      }
    </div>
  );
};

export default PlaylistsTable;
