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

function Pagination(props) {
  const handleClick = (page, event) => {
    event.preventDefault();
    props.changePage(page);
  };

  const pageStart = pages => {
    return pages.offset_value + 1;
  };

  const pageEnd = pages => {
    return Math.min(pages.offset_value + pages.limit_value, pages.total_count);
  };

  const paginationBlock = (
    <>
      {props.pages.prev_page != null ? (
        <a
          href="#"
          onClick={event => handleClick(props.pages.prev_page, event)}
        >
          Previous
        </a>
      ) : (
        <span>Previous</span>
      )}
      <span>
        {' '}
        | {pageStart(props.pages)}-{pageEnd(props.pages)} of{' '}
        {props.pages.total_count} |{' '}
      </span>
      {props.pages.next_page != null ? (
        <a
          href="#"
          onClick={event => handleClick(props.pages.next_page, event)}
        >
          Next
        </a>
      ) : (
        <span>Next</span>
      )}
    </>
  );
  if (props.pages.total_count) {
    return paginationBlock;
  } else {
    return null;
  }
}

export default Pagination;
