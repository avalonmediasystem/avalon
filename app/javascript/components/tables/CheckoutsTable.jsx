import React, { useMemo, useState } from 'react';
import GenericTable from './GenericTable';
import { Col } from 'react-bootstrap';

const CheckoutsTable = ({ url, isAdmin, returnAll }) => {
  const [indexUrl, setIndexUrl] = useState(url);
  const [showReturned, setShowReturned] = useState(false);

  /**
   * Refresh the chekouts when display returned items checkbox
   * is checked/unchecked
   */
  const refreshData = () => {
    const checked = showReturned;
    if (!checked) {
      setIndexUrl(`${url}?display_returned=true`);
    } else { setIndexUrl(url); }
    setShowReturned(!showReturned);
  };

  const checkoutsConfig = useMemo(() => {
    return {
      // Table metadata
      tableType: 'checkouts',
      containerClass: 'checkouts-table-container',
      testId: 'checkouts-table',
      hasTagFilter: false,

      // Table sorting and filtering keys from parsed data
      initialSort: isAdmin ? { columnKey: 'user' } : { columnKey: 'media_object_title' },
      searchableFields: isAdmin ? ['user', 'media_object_title'] : ['media_object_title'],

      columns: [
        isAdmin && { key: 'user', label: 'User', sortable: true, dataType: 'string' },
        { key: 'media_object', label: 'Media object', sortable: true, dataType: 'string', width: '20%' },
        { key: 'checkout_time', label: 'Checkout time', sortable: true, dataType: 'date', width: '20%' },
        { key: 'return_time', label: 'Return time', sortable: true, dataType: 'date', width: '20%' },
        { key: 'time_remaining', label: 'Time remaining', sortable: true, dataType: 'string' },
        { key: 'actions', label: <div dangerouslySetInnerHTML={{ __html: returnAll }} />, sortable: false }
      ],

      // Data parsing function to extract data from Checkouts API response
      parseDataRow: (row, index) => {
        let dataIndex = 0;

        const result = {};
        // Handle admin view with user column
        if (isAdmin) {
          result.user = row[dataIndex++];
          result.mediaObjectHtml = row[dataIndex++];
        } else {
          result.mediaObjectHtml = row[dataIndex++];
        }

        let rebuildAndFormatTimes = (html) => {
          const regex = /data-utc-time='([^']+)'/;
          const datetime = html.match(regex)?.[1];
          // Return original if no match
          if (!datetime) return { html, datetime: null };

          const actionDateTime = new Date(datetime);
          // Format date to a human readable format
          const formattedTime = actionDateTime.toLocaleString('en-US', {
            year: 'numeric', month: 'long', day: 'numeric',
            hour: 'numeric', minute: '2-digit', hour12: true
          });
          // Replace self-closing span with span containing text content
          const formattedHtml = html.replace(
            /<span([^>]*data-utc-time='[^']*'[^>]*)\s*\/>/,
            `<span$1>${formattedTime}</span>`
          );

          return { html: formattedHtml, datetime: actionDateTime };
        };

        let getId = (html) => {
          const checkoutIdMatch = html.match(/\/checkouts\/(\d+)\/return/);
          const checkoutId = checkoutIdMatch ? checkoutIdMatch[1] : `checkout-${index}`;
          return checkoutId;
        };

        // Parse checkout and return times
        const { html: checkoutTimeHtml, datetime: checkout_time } = rebuildAndFormatTimes(row[dataIndex++]);
        const { html: returnTimeHtml, datetime: return_time } = rebuildAndFormatTimes(row[dataIndex++]);

        const mediaObjectMatch = result.mediaObjectHtml.match(/<a[^>]*>(.*?)<\/a>/);

        return {
          ...result,
          media_object_title: mediaObjectMatch ? mediaObjectMatch[1] : '',
          checkoutTimeHtml, checkout_time,
          returnTimeHtml, return_time,
          timeRemaining: row[dataIndex++],
          actionsHtml: row[dataIndex],
          id: getId(row[dataIndex])
        };
      },

      // Cell rendering function for each column key
      renderCell: (item, columnKey) => {
        switch (columnKey) {
          case 'user':
            return item.user;
          case 'media_object':
            return (
              <div dangerouslySetInnerHTML={{ __html: item.mediaObjectHtml }} />
            );
          case 'checkout_time':
            return (
              <div dangerouslySetInnerHTML={{ __html: item.checkoutTimeHtml }} />
            );
          case 'return_time':
            return (
              <div dangerouslySetInnerHTML={{ __html: item.returnTimeHtml }} />
            );
          case 'time_remaining':
            return item.timeRemaining;
          case 'actions':
            return (
              <div dangerouslySetInnerHTML={{ __html: item.actionsHtml }} />
            );
          default:
            return item[columnKey];
        }
      },

      displayReturnedItemsHTML: (
        <Col span={3} offset={9} className='mb-2 text-end text-nowrap'>
          <input type='checkbox' checked={showReturned} id='inactive_checkouts' onChange={refreshData} />
          <label className='fw-bold ms-1' htmlFor='inactive_checkouts'>Display Returned Items</label>
        </Col>
      )
    };
  }, [isAdmin, showReturned]);

  return <GenericTable config={checkoutsConfig} url={indexUrl} isAdmin={isAdmin} httpMethod='GET' />;
};

export default CheckoutsTable;
