import React, { useState, useMemo } from 'react';

/**
 * Custom hook for managing table pagination functionality
 * @param {Object} dataState data state from useTableData
 * @returns {Object} pagination state and functions
 */
const useTablePagination = (dataState) => {
  const [pagination, setPagination] = useState({
    pageIndex: 0,
    pageSize: 10,
    pages: [],
  });

  const { sortedRows, setRowsToShow, filteredRowCount } = dataState;

  const totalPages = useMemo(() => {
    return Math.ceil(filteredRowCount / pagination.pageSize);
  }, [pagination.pageSize, filteredRowCount]);

  const currentPage = useMemo(() => {
    return pagination.pageIndex + 1;
  }, [pagination.pageIndex]);

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

  /**
   * Build pagination page numbers list based on the currentPage and totalPages count
   * @returns {Array}
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

  return {
    // State
    pagination,
    totalPages,
    currentPage,

    // Setters
    setPagination,

    // Functions
    handlePageChange,
    handlePageSizeChange,
    getPaginationPages
  };
};

export default useTablePagination;
