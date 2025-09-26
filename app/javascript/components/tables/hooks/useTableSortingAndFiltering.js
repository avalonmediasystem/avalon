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

import React, { useState } from 'react';

/**
 * Custom hook for managing table sorting and filtering functionalities
 * @param {Object} params
 * @param {Array} params.columns column configuration array
 * @param {Object} params.dataState data state from useTableData
 * @param {Object} params.initialSort data for initial sorting on data load
 * @param {Object} params.pagination pagination state from useTablePagination
 * @param {Array} params.searchableFields list of fields to be searched in the search filter
 * @returns {Object} sorting and filtering related state and functions
 */
const useTableSortingAndFiltering = ({ columns, dataState, initialSort, pagination, searchableFields }) => {
  // By default initial sort is performed on the first column in 'asc' order unless overwritten via initialSort
  const [sorting, setSorting] = useState({ column: 0, direction: 'asc', ...initialSort });

  const { dataRows, setSortedRows, setFilteredRowCount, setRowsToShow, sortedRows } = dataState;
  const { setPagination } = pagination;

  const [searchFilter, setSearchFilter] = useState('');
  const [tagFilter, setTagFilter] = useState('');

  /**
   * Filter sorted rows by search and tag values
   * @param {String} searchQ search query from search field
   * @param {String} tag selected tag from the tag filter
   * @param {Array} sortedData most recently sorted rows
   */
  const filterRows = (searchQ, tag, sortedData = sortedRows) => {
    let filtered = sortedData;

    // Filter on search from searchable fields
    if (searchQ.trim() !== '') {
      filtered = filtered.filter(row => {
        return searchableFields.some(field =>
          row[field]?.toString().toLowerCase().includes(searchQ.toLowerCase())
        );
      });
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

    // Set filteredRowCount to be used in the text on top of the table
    setFilteredRowCount(filtered?.length);

    // Apply pagination to filtered data
    const pageSize = pagination.pagination.pageSize;
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

  /**
   * Handle search input change
   * @param {Object} e change event from the search input field
   */
  const handleSearch = (e) => {
    const filter = e.target.value;
    setSearchFilter(filter);
    filterRows(filter, tagFilter);
  };

  /**
   * Handle tag filter changes
   * @param {Object} e change event from the tag filter drop-down
   */
  const handleTagFilter = (e) => {
    const filter = e.target.value;
    setTagFilter(filter);
    filterRows(searchFilter, filter);
  };

  /**
   * Sort rows by a given column key and direction (asc/desc)
   * @param {Array} rows
   * @param {String} columnKey column name to be used for sorting
   * @param {String} direction sorting direction (asc/desc)
   * @param {String} dataType data type of the column (string, number, date)
   * @returns {Array}
   */
  const sortRows = (rows, columnKey, direction = 'asc', dataType = 'string') => {
    let sorted;

    switch (dataType) {
      case 'date':
        // Sort by date values from the parsed timestamps
        sorted = rows.sort((a, b) => {
          return a[columnKey] - b[columnKey];
        });
        break;

      case 'number':
        // Sort by numeric values
        sorted = rows.sort((a, b) => {
          const numA = parseFloat(a[columnKey]) || 0;
          const numB = parseFloat(b[columnKey]) || 0;
          return numA - numB;
        });
        break;

      case 'string':
      default:
        // Case-insensitive sort with stable fallback
        sorted = rows.sort((a, b) => {
          const aVal = (a[columnKey] || '').toString().toLowerCase();
          const bVal = (b[columnKey] || '').toString().toLowerCase();

          // Primary sort: case-insensitive comparison
          if (aVal < bVal) return -1;
          if (aVal > bVal) return 1;

          // Secondary sort: original case-sensitive value for stable sort
          const aOriginal = (a[columnKey] || '').toString();
          const bOriginal = (b[columnKey] || '').toString();
          if (aOriginal < bOriginal) return -1;
          if (aOriginal > bOriginal) return 1;
          return 0;
        });
        break;
    }

    return direction === 'asc' ? sorted : sorted.reverse();
  };

  /**
   * Handle sorting when a column header is clicked
   * @param {Number} columnIndex column index of the sorting column
   * @returns 
   */
  const handleSort = (columnIndex) => {
    if (!columns[columnIndex].sortable) return;

    const column = columns[columnIndex];
    const columnKey = column.key;
    const dataType = column.dataType || 'string';

    let sortDirection;
    if (sorting.column === columnIndex) {
      // Toggle direction if the same column is clicked
      sortDirection = sorting.direction === 'asc' ? 'desc' : 'asc';
    } else {
      // Choose appropriate initial direction based on data type
      if (dataType === 'date') {
        // Date columns: starts with most recent first
        sortDirection = 'desc';
      } else if (dataType === 'number') {
        // Number columns: starts with smallest first
        sortDirection = 'asc';
      } else {
        // Text columns: starts with A-Z
        sortDirection = 'asc';
      }
    }

    // Sort the current working dataset
    const sortedData = sortRows(dataRows, columnKey, sortDirection, dataType);
    setSortedRows(sortedData);
    // Apply filters on top of sorted rows
    filterRows(searchFilter, tagFilter, sortedData);

    setSorting({ column: columnIndex, direction: sortDirection, columnKey });
  };

  /**
   * Get the sort icon for asc/desc for a column header
   * @param {Number} columnIndex 
   * @returns {Object}
   */
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

  return {
    // State
    sorting,
    searchFilter,
    tagFilter,

    // Functions
    sortRows,
    handleSearch,
    handleSort,
    handleTagFilter,
    getSortIcon
  };
};

export default useTableSortingAndFiltering;
