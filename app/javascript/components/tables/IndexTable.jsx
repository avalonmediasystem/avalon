import React, { useState, useEffect, useMemo } from 'react';

const IndexTable = ({ url, tags }) => {
  const [data, setData] = useState([]);
  const [rowsToShow, setRowsToShow] = useState(data);
  const [loading, setLoading] = useState(false);
  const [pagination, setPagination] = useState({
    pageIndex: 0,
    pageSize: 5,
    pages: [],
  });
  const [sorting, setSorting] = useState({ column: 0, direction: 'asc' });
  const [titleFilter, setTitleFilter] = useState('');
  const [tagFilter, setTagFilter] = useState('');
  const [totalRows, setTotalRows] = useState(0);
  const [filteredRows, setFilteredRows] = useState(0);

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

    const payload = {
      draw: Date.now(),
      start: pagination.pageIndex * pagination.pageSize,
      search: { value: titleFilter },
      order: { '0': { column: sorting.column, dir: sorting.direction } },
      columns: {
        '5': { search: { value: tagFilter } }
      }
    };

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content'),
        },
        body: JSON.stringify(payload)
      });

      const result = await response.json();

      // Parse the Rails response data
      const parsedData = result.data.map((row, index) => {
        // Extract title from link HTML
        const titleMatch = row[0].match(/<a[^>]*href="[^"]*\/playlists\/(\d+)"[^>]*title="([^"]*)"[^>]*>([^<]*)<\/a>/);
        const playlistId = titleMatch ? titleMatch[1] : index;
        const title = titleMatch ? titleMatch[3] : row[0];
        const titleTooltip = titleMatch ? titleMatch[2] : '';

        return {
          id: playlistId,
          title: title,
          titleTooltip: titleTooltip,
          titleHtml: row[0],
          size: parseInt(row[1].split(' ')[0]) || 0,
          sizeText: row[1],
          visibilityHtml: row[2],
          createdAt: row[3].match(/title='(.*?)'/)?.[1] || '',
          createdAgo: row[3].match(/>(.*?) ago</)?.[1] + ' ago' || row[3],
          createdHtml: row[3],
          updatedAt: row[4].match(/title='(.*?)'/)?.[1] || '',
          updatedAgo: row[4].match(/>(.*?) ago</)?.[1] + ' ago' || row[4],
          updatedHtml: row[4],
          tags: row[5],
          actionsHtml: row[6]
        };
      });

      setData(parsedData);
      setRowsToShow(parsedData);
      setTotalRows(result.recordsTotal);
      setFilteredRows(result.recordsTotal);
      // setFilteredRows(result.recordsFiltered);
      setPagination(prev => ({ ...prev, pages: Array.from({ length: Math.ceil(parsedData / prev.pageSize) }, (_, i) => i + 1) }));
    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [pagination.pageIndex, pagination.pageSize, sorting]);

  const handleSort = (columnIndex) => {
    if (!columns[columnIndex].sortable) return;

    setSorting(prev => ({
      column: columnIndex,
      direction: prev.column === columnIndex && prev.direction === 'asc' ? 'desc' : 'asc'
    }));
    setPagination(prev => ({ ...prev, pageIndex: 0 }));
  };

  const handlePageChange = (newPageIndex) => {
    setPagination(prev => ({ ...prev, pageIndex: newPageIndex }));
  };

  const handlePageSizeChange = (newPageSize) => {
    setSelectedRows(data[0..newPageSize]);
    setPagination({ pageIndex: 0, pageSize: newPageSize });
  };

  const handleSearch = (e) => {
    const filter = e.target.value;
    setTitleFilter(filter);
    setFilteredData(filter, tagFilter);
  };

  const handleTagFilter = (e) => {
    const filter = e.target.value;
    setTagFilter(filter);
    setFilteredData(titleFilter, filter);
  };

  const setFilteredData = (title, tag) => {
    let filtered = data;

    // Apply title filter first
    if (title.trim() !== '') {
      filtered = filtered.filter(row =>
        row.title.toLowerCase().includes(title.toLowerCase())
      );
    }

    // Then apply tag filter on top of title-filtered data
    if (tag.trim() !== '') {
      filtered = filtered.filter(row =>
        Array.isArray(row.tags)
          ? row.tags.includes(tag)
          : (typeof row.tags === 'string' && row.tags.split(',').map(t => t.trim()).includes(tag))
      );
    }

    setFilteredRows(filtered?.length);
    setRowsToShow(filtered);
    setPagination(prev => ({
      ...prev,
      pageIndex: 0,
      pages: Array.from({ length: Math.ceil(filtered?.length / prev.pageSize) }, (_, i) => i + 1)
    }));
  };

  const totalPages = Math.ceil(filteredRows / pagination.pageSize);
  const currentPage = pagination.pageIndex + 1;

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

      // File data change handlers
      document.querySelectorAll('.filedata').forEach(input => {
        input.addEventListener('change', function () {
          this.closest('form').submit();
        });
      });
    }
  }, [loading, rowsToShow]);

  const searchAndFilter = useMemo(() => {
    return (
      <div className="d-flex justify-content-between align-items-center mb-3 flex-sm-wrap">
        <div>
          {(rowsToShow?.length === 0 && !loading)
            ? 'Showing 0 to 0 of 0 entries'
            : `Showing ${pagination.pageIndex * pagination.pageSize + 1} to${' '}
          ${Math.min((pagination.pageIndex + 1) * pagination.pageSize, filteredRows)} of${' '}
          ${filteredRows} entries`}
          {filteredRows < totalRows && ` (filtered from ${totalRows} total entries)`}
        </div>
        <div className='d-flex justify-content-end gap-2 flex-sm-wrap'>
          <div className="d-flex align-items-center">
            <label htmlFor="search-playlist" className="me-2 mb-0">Search:</label>
            <input
              id="search-playlist"
              type="text"
              className="form-control"
              placeholder="Search playlists..."
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
  }, [tags, filteredRows, pagination, totalRows]);

  const getPaginationPages = (currentPage, totalPages) => {
    if (totalPages <= 5) {
      return Array.from({ length: totalPages }, (_, i) => i + 1);
    }

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
                    <td colSpan={columns.length} className="text-center py-1">
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
                {getPaginationPages(currentPage, totalPages).map((page, idx) =>
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

export default IndexTable;
