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

import { useState, useEffect, useCallback, useRef } from 'react';

/**
 * Custom hook for managing progress updates for encoding jobs.
 * Polls the server every 10 seconds for jobs that are still running.
 * @param {Object} params Hook parameters
 * @param {Array} params.currentJobs array of current job data
 * @param {Function} params.onProgressUpdate callback function to handle progress updates
 * @param {String} params.progressUrl URL endpoint to fetch progress updates
 */
const useProgressUpdates = ({ currentJobs, onProgressUpdate, progressUrl }) => {
  const [activeJobIds, setActiveJobIds] = useState([]);
  const timeoutRef = useRef(null);
  const mountedRef = useRef(true);

  // Clear any existing timeout
  const clearTimeoutRef = () => {
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
      timeoutRef.current = null;
    }
  };

  useEffect(() => {
    const jobs = currentJobs
      .filter(job => {
        const status = job.status?.toLowerCase();
        return status && status === 'running' && job.progress < 100;
      })
      .map(job => job.id);

    if (jobs?.length > 0) {
      setActiveJobIds(jobs);
    }
  }, [currentJobs]);

  // Function to fetch progress updates from the server
  const fetchProgressUpdates = async (jobIds) => {
    if (!jobIds.length) return null;

    try {
      const response = await fetch(progressUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content'),
        },
        body: JSON.stringify({ ids: jobIds })
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      console.error('Error fetching progress updates:', error);
      return null;
    }
  };

  /**
   * Update function that polls for progress updates.
   */
  const updateProgress = useCallback(async () => {
    if (!mountedRef.current || activeJobIds.length === 0) return;

    fetchProgressUpdates(activeJobIds)
      .then(progressData => {
        if (progressData && mountedRef.current) {
          onProgressUpdate(progressData);

          // Check if there are running encoding jobs
          const stillRunning = Object.values(progressData).some(job =>
            job.progress < 100 && job.status?.toLowerCase() === 'running'
          );
          if (stillRunning) {
            // Clear any existing timeouts
            clearTimeoutRef();
            // Schedule next update
            timeoutRef.current = setTimeout(updateProgress, 10000);
          } else {
            setActiveJobIds([]);
          }
        }
      });
  }, [activeJobIds, onProgressUpdate]);

  // Start polling when encoding jobs are present and changing
  useEffect(() => {
    clearTimeoutRef();
    if (activeJobIds.length > 0) {
      // Start updates
      updateProgress();
    }
  }, [currentJobs, activeJobIds, updateProgress]);

  // Cleanup on unmount
  useEffect(() => {
    mountedRef.current = true;

    return () => {
      mountedRef.current = false;
      clearTimeoutRef();
    };
  }, []);
};

export default useProgressUpdates;
