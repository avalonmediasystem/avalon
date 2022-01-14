// Copyright 2011-2022, The Trustees of Indiana University and Northwestern
//   University.  Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed
//   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied. See the License for the
//   specific language governing permissions and limitations under the License.

/**
 * @class MEJSTimeRailHelper
 * @classdesc Helper class to support Mediaelement 4's time rail highlighting functions
 */
class MEJSTimeRailHelper {
  /**
   * Calculate a time array based on segment and current stream info
   * @param  {Object} segment           Segment object
   * @param  {Object} currentStreamInfo Current stream information object
   * @return {Array}                    Array used representing clip start/stop values
   */
  calculateSegmentT(segment, currentStreamInfo) {
    let t = [];

    // Use the active segment fragment,
    try {
      t = [parseFloat(segment.fragmentbegin), parseFloat(segment.fragmentend)];
    } catch (e) {
      t = currentStreamInfo.t.slice(0);
    }

    // Ensure t range array has valid values
    t[0] = isNaN(parseFloat(t[0])) ? 0 : t[0];
    t[1] =
      t.length < 2 || isNaN(parseFloat(t[1]))
        ? currentStreamInfo.duration
        : t[1];

    return t;
  }

  /**
   * Create an element representing highlighted segment area in MEJS's time rail
   * and add it to the DOM
   * @function createTimeHighlightEl
   * @return {void}
   */
  createTimeHighlightEl(contentEl) {
    let highlightSpanEl = contentEl
      ? contentEl.querySelector('.mejs-highlight-clip')
      : null;

    // Create the highlight DOM element if doesn't exist
    if (!highlightSpanEl) {
      highlightSpanEl = document.createElement('span');
      highlightSpanEl.classList.add('mejs-highlight-clip');
      this.getTimeRail().appendChild(highlightSpanEl);
    }
    return highlightSpanEl;
  }

  /**
   * Create a CSS 'style' string to plug into an inline style attribute
   * @function createTimeRailStyles
   * @return {string} Ex. left: 10%; width: 50%;
   */
  createTimeRailStyles(t, currentStreamInfo) {
    const duration = currentStreamInfo.duration;

    // No active segment, remove highlight style
    // if (!activeSegmentId) {
    //   return 'left: 0%; width: 0%;'
    // }

    // Calculate start and end percentage values for the highlight style attribute
    let startPercent = Math.round(t[0] / duration * 100);
    startPercent = Math.max(0, Math.min(100, startPercent));
    let endPercent = Math.round(t[1] / duration * 100);
    endPercent = Math.max(0, Math.min(100, endPercent));

    // Make the length of time highlight 0 if it would span the entire time length
    if (startPercent === 0 && endPercent === 100) {
      endPercent = 0;
    }
    return (
      'left: ' +
      startPercent +
      '%; width: ' +
      (endPercent - startPercent) +
      '%;'
    );
  }

  /**
   * Helper function which handles re-initializing a track scrubber
   * @function getUpdatedRangeTimes
   * @param {Array} t Start end time array
   * @param {string} activeSegmentId - Active segment id
   * @return {void}
   */
  /* eslint-disable complexity */
  getUpdatedRangeTimes(t, activeSegmentId, stream) {
    let start = null;
    let end = null;

    // If there's an active section, update start / end values to active section values
    if (
      activeSegmentId &&
      this.segmentsMap &&
      this.segmentsMap.hasOwnProperty(activeSegmentId)
    ) {
      start = this.segmentsMap[activeSegmentId].fragmentbegin;
      end = this.segmentsMap[activeSegmentId].fragmentend;
      return [start, end];
    }

    // If t array start / end values are passed in, use these
    if (t.length > 0) {
      start = t[0] || 0;
      end = t[1] || 0;
    } else {
      // Next option, use starting values on the stream object as default values
      start = stream.t[0] || 0;
      end = stream.t[1] || stream.duration;
    }
    return [start, end];
  }
  /* eslint-enable complexity */

  getTimeRail() {
    return $('.mejs__time-total')[0];
  }
}
