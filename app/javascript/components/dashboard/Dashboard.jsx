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
      <div className="d-flex justify-content-between page-title-wrapper mb-3">
        <h1 className="page-title mb-0">My Units</h1>
        {can_create_unit && (
          <div className="collection-btn">
            <a href={new_unit_path}>
              <span className="btn btn-primary btn-large" data-testid="unit-create-unit-button">
                <i className="fa fa-plus" aria-hidden="true"></i> Create Unit
              </span>
            </a>
          </div>
        )}
      </div>

      {units.length === 0 ? (
        <div className="hero-unit mb-4">
          <h2>You don&apos;t have any units yet</h2>
          {can_create_unit && (
            <p>
              <a href={new_unit_path}>
                <span className="btn btn-primary btn-large"><i class="fa fa-plus" aria-hidden="true"></i> Create Unit</span>
              </a>
            </p>
          )}
        </div>
      ) : (
        <div className="mb-5">
          <UnitsTable data={units} />
        </div>
      )}

      <div className="d-flex justify-content-between page-title-wrapper mb-3">
        <h1 className="page-title mb-0">My Collections</h1>
        {can_create_collection && (
          <div className="collection-btn">
            <a href={new_collection_path}>
              <span className="btn btn-outline btn-large" data-testid="collection-create-collection-button">
                <i className="fa fa-plus" aria-hidden="true"></i> Create Collection
              </span>
            </a>
          </div>
        )}
      </div>

      {collections.length === 0 ? (
        <div className="hero-unit">
          <h2>You don&apos;t have any collections yet</h2>
          {can_create_collection && (
            <p>
              <a href={new_collection_path}>
                <span className="btn btn-outline btn-large">
                  <i class="fa fa-plus" aria-hidden="true"></i> Create Collection
                </span>
              </a>
            </p>
          )}
        </div>
      ) : (
        <CollectionsTable data={collections} />
      )}
    </div>
  );
};

export default Dashboard;
