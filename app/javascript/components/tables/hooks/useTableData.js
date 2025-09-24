import { useState, useEffect } from 'react';

/**
 * Custom hook for managing table data i.e. fetching, parsing, and state management
 * @param {Object} params
 * @param {String} params.url API endpoint URL
 * @param {Function} params.parseDataRow  function to parse each data row from API response
 * @param {Object} params.pagination { currentPage, pageSize } for pagination
 * @param {Array} params.sortRows function to sort rows
 * @param {String} params.initialSort { columnKey, dataType, direction } for initial sort on load
 * @param {String} params.httpMethod HTTP method to use for requests (default: 'POST')
 * @returns {Object} data state and functions
 */
const useTableData = ({ url, parseDataRow, pagination, sortRows, initialSort, httpMethod = 'POST' }) => {
  const [dataRows, setDataRows] = useState([]);
  const [sortedRows, setSortedRows] = useState([]);
  const [rowsToShow, setRowsToShow] = useState([]);
  const [loading, setLoading] = useState(false);
  const [totalRowCount, setTotalRowCount] = useState(0);
  const [filteredRowCount, setFilteredRowCount] = useState(0);

  const fetchData = async () => {
    setLoading(true);

    try {
      const response = await fetch(url, {
        method: httpMethod,
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content'),
        },
      });

      const result = await response.json();

      // Parse the server response data using the provided parsing function
      const parsedData = result.data.map(parseDataRow);

      setTotalRowCount(result.recordsTotal);
      setFilteredRowCount(result.recordsTotal);
      setDataRows(parsedData);

      // Sort the initial data set by the given column key
      const { columnKey, dataType, direction } = initialSort;
      const sortedData = sortRows(parsedData, columnKey, direction, dataType);
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

  useEffect(() => { fetchData(); }, []);

  return {
    // State
    dataRows,
    sortedRows,
    rowsToShow,
    loading,
    totalRowCount,
    filteredRowCount,

    // Setters
    setSortedRows,
    setRowsToShow,
    setFilteredRowCount,
  };
};

export default useTableData;
