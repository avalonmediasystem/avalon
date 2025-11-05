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

import React, { useMemo, useState } from 'react';
import GenericTable from './GenericTable';
import { Col } from 'react-bootstrap';

/**
 * Render a table displaying checkout records.
 * @param {Object} props
 * @param {String} props.url API endpoint URL for fetching checkouts data
 * @param {Boolean} props.isAdmin flag indicating if the current user is an admin
 * @param {String} props.returnAll HTML string for the "Return All" action link
 */
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

      // Table sorting and filtering keys from parsed data (keys match column keys and parsed data keys)
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
        const { html: checkouttime_html, datetime: checkout_time } = rebuildAndFormatTimes(row[dataIndex++]);
        const { html: returntime_html, datetime: return_time } = rebuildAndFormatTimes(row[dataIndex++]);

        const mediaObjectMatch = result.mediaObjectHtml.match(/<a[^>]*>(.*?)<\/a>/);

        return {
          ...result,
          media_object_title: mediaObjectMatch ? mediaObjectMatch[1] : '',
          checkouttime_html, checkout_time,
          returntime_html, return_time,
          time_remaining: row[dataIndex++],
          actions_html: row[dataIndex],
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
              <div dangerouslySetInnerHTML={{ __html: item.checkouttime_html }} />
            );
          case 'return_time':
            return (
              <div dangerouslySetInnerHTML={{ __html: item.returntime_html }} />
            );
          case 'time_remaining':
            return item.time_remaining;
          case 'actions':
            return (
              <div dangerouslySetInnerHTML={{ __html: item.actions_html }} />
            );
          default:
            return item[columnKey];
        }
      },

      displayReturnedItemsHTML: (
        <Col span={3} offset={9} className='mb-2 text-end text-nowrap'>
          <input type='checkbox' checked={showReturned} id='inactive_checkouts' data-testid='bookmark-display-returned-items-chkbox' onChange={refreshData} />
          <label className='fw-bold ms-1' htmlFor='inactive_checkouts'>Display Returned Items</label>
        </Col>
      )
    };
  }, [isAdmin, showReturned]);

  return <GenericTable config={checkoutsConfig} url={indexUrl} isAdmin={isAdmin} httpMethod='GET' />;
};

export default CheckoutsTable;
