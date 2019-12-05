import React from 'react';

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
