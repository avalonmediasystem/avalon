import React, { useState } from 'react';
import PropTypes from 'prop-types';

const CollectionDescription = ({ content }) => {
  const wordCount = 40;
  const words = content.split(' ');
  const [expanded, setExpanded] = useState(false);
  const [description, setDescription] = useState(prepInitialDescription());

  function prepInitialDescription() {
    return words.length > wordCount
      ? words.slice(0, wordCount).join(' ')
      : words.join(' ');
  }

  const handleClick = () => {
    setDescription(
      expanded ? words.slice(0, wordCount).join(' ') : words.join(' ')
    );
    setExpanded(!expanded);
  };

  return (
    <div>
      <p className="lead document-description">{description}</p>
      {words.length > wordCount && (
        <button className="btn btn-link" onClick={handleClick}>
          <i
            className={`glyphicon glyphicon-${
              expanded ? 'menu-up' : 'menu-right'
            }`}
          ></i>{' '}
          Show {expanded ? 'less' : 'more'}
        </button>
      )}
    </div>
  );
};

CollectionDescription.propTypes = {
  content: PropTypes.string
};

export default CollectionDescription;
