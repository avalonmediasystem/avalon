/*
 * Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

import { useState, useMemo } from 'react';

/**
 * Custom hook for managing table pagination functionality and state
 * @param {Object} params required data state from useTableData hook
 * @param {Number} params.initPageSize initial page size for the table
 * @param {Array} params.sortedRows sorted rows from useTableData hook
 * @param {Function} params.setRowsToShow function to set the rows to show in the table
 * @param {Number} params.filteredRowCount number of rows after filtering
 * @returns {Object} pagination state and functions
 */
const useTablePagination = ({ initPageSize, sortedRows, setRowsToShow, filteredRowCount }) => {
  const [pagination, setPagination] = useState({
    pageIndex: 0,
    pageSize: initPageSize,
    pages: [],
  });

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
