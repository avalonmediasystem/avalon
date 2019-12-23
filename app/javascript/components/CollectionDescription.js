/*
 * Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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

import React, { useState } from 'react';
import PropTypes from 'prop-types';

const CollectionDescription = ({ content = '' }) => {
  if (!content) return null;

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
