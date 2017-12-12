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
    let t = []

    // Use the active segment fragment,
    try {
      t = [parseFloat(segment.fragmentbegin), parseFloat(segment.fragmentend)]
    } catch(e) {
      t = currentStreamInfo.t.slice(0)
    }

    // Ensure t range array has valid values
    t[0] = (isNaN(parseFloat(t[0]))) ? 0 : t[0]
    t[1] = (t.length < 2 || isNaN(parseFloat(t[1]))) ? currentStreamInfo.duration : t[1]

    return t
  }

  /**
   * Create an element representing highlighted segment area in MEJS's time rail
   * and add it to the DOM
   * @function createTimeHighlightEl
   * @return {void}
   */
  createTimeHighlightEl (contentEl) {
    let highlightSpanEl = (contentEl) ? contentEl.querySelector('.mejs-highlight-clip') : null

    // Create the highlight DOM element if doesn't exist
    if (!highlightSpanEl) {
      highlightSpanEl = document.createElement('span')
      highlightSpanEl.classList.add('mejs-highlight-clip')
      $('.mejs__time-total')[0].appendChild(highlightSpanEl)
    }
    return highlightSpanEl
  }

  /**
   * Create a CSS 'style' string to plug into an inline style attribute
   * @function createTimeRailStyles
   * @return {string} Ex. left: 10%; width: 50%;
   */
  createTimeRailStyles (t, currentStreamInfo) {
    const duration = currentStreamInfo.duration

    // No active segment, remove highlight style
    // if (!activeSegmentId) {
    //   return 'left: 0%; width: 0%;'
    // }

    // Calculate start and end percentage values for the highlight style attribute
    let startPercent = Math.round((t[0] / duration) * 100)
    startPercent = Math.max(0, Math.min(100, startPercent))
    let endPercent = Math.round((t[1] / duration) * 100)
    endPercent = Math.max(0, Math.min(100, endPercent))

    // Make the length of time highlight 0 if it would span the entire time length
    if (startPercent === 0 && endPercent === 100) {
      endPercent = 0
    }
    return 'left: ' + startPercent + '%; width: ' + (endPercent - startPercent) + '%;'
  }
}
