/*
 * Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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

import { useEffect, useState } from 'react';
import UnitsTable from './UnitsTable';
import CollectionsTable from './CollectionsTable';

/**
 * Truncate a description text to a maximum length and append an
 * ellipsis at the end if truncated
 * @param {String} text description text
 * @param {Number} maxChars character limit (default 120)
 * @returns {String}
 */
const truncateDescription = (text, maxChars = 120) =>
  text ? text.substring(0, maxChars) + (text.length > maxChars ? '…' : '') : '';

/**
 * Shared edit/delete action button pair used by dashboard table rows
 */
const DashboardActionButtons = ({ editUrl, removeUrl, editTitle, deleteTitle, deleteTestId }) => (
  <div className="dashboard-action-icons">
    {editUrl != '' && (
      <a href={editUrl} className="dashboard-action-edit btn btn-outline btn-sm text-nowrap" title={editTitle}>
        <i className="fa-regular fa-pen-to-square me-1" />Edit
      </a>
    )}
    {/* Render the delete button only when the current user has permissions to destroy item */}
    {removeUrl != '' && (
      <a href={removeUrl} className="dashboard-action-delete btn btn-danger btn-sm text-nowrap" title={deleteTitle} data-testid={deleteTestId}>
        <i className="fa-regular fa-trash-can me-1" />Delete
      </a>
    )}
  </div>
);

/**
 * Render dashboard section with either a table or a message for units or collections
 * according to the provided data
 * @param {Object} props
 * @param {Array} props.data section data from the API
 * @param {Boolean} props.canCreate whether the current user can create a unit/collection
 * @param {String} props.createPath path for creating a new unit/collection
 * @param {String} props.createLabel create button label
 * @param {String} props.btnClass create button Bootstrap class name
 * @param {String} props.sectionType section object type (unit/collection)
 * @param {React.Component} props.TableComponent relevant React component for the data table
 * @param {String} props.tableWrapperClass table wrapper Bootstrap class name
 */
const DashboardSection = ({ data, canCreate, createPath, btnClass, sectionType, TableComponent, tableWrapperClass }) => {
  const helpers = { truncateDescription, DashboardActionButtons };

  if (data.length > 0) {
    return (
      <>
        <div className="d-flex justify-content-between page-title-wrapper mb-3">
          <h1 className="page-title mb-0 section-title">{`My ${sectionType}s`}</h1>
          {canCreate && (
            <a href={createPath}>
              <span className={`btn ${btnClass} btn-large section-create-button`} data-testid={`${sectionType}-create-${sectionType}-button`}>
                <i className="fa fa-plus" aria-hidden="true"></i> {`Create ${sectionType}`}
              </span>
            </a>
          )}
        </div>
        <div className={tableWrapperClass}>
          <TableComponent data={data} helpers={helpers} />
        </div>
      </>
    );
  }

  return (
    <div className="mb-4">
      <h2>You don&apos;t have any {sectionType}s yet</h2>
      {canCreate
        ? (
          <div className="d-flex justify-content-between mt-4">
            <p>Would you like to create one?</p>
            <p>
              <a href={createPath}>
                <span className={`btn ${btnClass} btn-large section-create-button`} data-testid={`${sectionType}-create-${sectionType}-button`}>
                  <i className="fa fa-plus" aria-hidden="true"></i> {`Create ${sectionType}`}
                </span>
              </a>
            </p>
          </div>
        )
        : <p>You&apos;ll need to be assigned to one</p>
      }
    </div>
  );
};

/**
 * Admin dashboard component — fetches units, collections, and summary stats
 * from the dashboard JSON endpoint and composes the page layout.
 *
 * @param {Object} props
 * @param {String}  props.url URL for the dashboard JSON endpoint
 * @param {String}  props.new_unit_path Path for creating a new unit
 * @param {String}  props.new_collection_path Path for creating a new collection
 * @param {Boolean} props.can_create_unit Whether the current user can create units
 * @param {Boolean} props.can_create_collection Whether the current user can create collections
 */
const Dashboard = ({ url, new_unit_path, new_collection_path, can_create_unit, can_create_collection }) => {
  const [loading, setLoading] = useState(true);
  const [units, setUnits] = useState([]);
  const [collections, setCollections] = useState([]);

  useEffect(() => {
    const fetchDashboard = async () => {
      try {
        const response = await fetch(url, {
          headers: {
            'Accept': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content'),
          },
        });
        const data = await response.json();
        setUnits(data.units || []);
        setCollections(data.collections || []);
      } catch (error) {
        console.error('Error fetching dashboard data:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchDashboard();
  }, [url]);

  if (loading) {
    return (
      <div className="text-center py-5">
        <div className="spinner-border" role="status">
          <span className="visually-hidden">Loading...</span>
        </div>
      </div>
    );
  }

  return (
    <div>
      <DashboardSection
        data={units}
        canCreate={can_create_unit}
        createPath={new_unit_path}
        btnClass="btn-outline"
        sectionType="unit"
        TableComponent={UnitsTable}
        tableWrapperClass="mb-5"
      />
      <DashboardSection
        data={collections}
        canCreate={can_create_collection}
        createPath={new_collection_path}
        btnClass="btn-outline"
        sectionType="collection"
        TableComponent={CollectionsTable}
        tableWrapperClass=""
      />
    </div>
  );
};

export default Dashboard;
