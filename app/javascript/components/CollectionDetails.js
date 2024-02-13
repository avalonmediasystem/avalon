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

import React, { useState } from 'react';
import PropTypes from 'prop-types';

const expandBtn = {
  paddingLeft: '2px'
};

const descriptionStyle = {
  fontSize: '16px',
  fontWeight: '200',
};

const CollectionDetails = ({ content = '', email = '', website = '' }) => {

  const wordCount = 40;
  const words = content ? content.split(' ') : [];
  const [expanded, setExpanded] = useState(false);
  const [description, setDescription] = useState(prepInitialDescription());

  function prepInitialDescription() {
    return words.length > wordCount
      ? `${words.slice(0, wordCount).join(' ')}...`
      : words.join(' ');
  }

  const handleClick = () => {
    setDescription(
      expanded ? `${words.slice(0, wordCount).join(' ')}...` : words.join(' ')
    );
    setExpanded(!expanded);
  };

  return (
    <div>
      {words.length > 0 && (
        <p className="lead document-description">{description}
          {words.length > wordCount && (
            <a className="btn btn-link" style={expandBtn} onClick={handleClick}>
              Show {expanded ? 'less' : 'more'}
            </a>
          )}
        </p>
      )}
      <dl className="row collection-details">
        {email &&
          <React.Fragment>
            <dt style={descriptionStyle} className="col-sm-3">Contact email:</dt>
            <dd className='col-sm-9'><a href={`mailto:${email}`}>{email}</a></dd>
          </React.Fragment>
        }
        {website &&
          <React.Fragment>
            <dt style={descriptionStyle} className="col-sm-3">Website:</dt>
            <dd className='col-sm-9' dangerouslySetInnerHTML={{ __html: website }}></dd>
          </React.Fragment>
        }
      </dl>
    </div>
  );
};

CollectionDetails.propTypes = {
  content: PropTypes.string,
  email: PropTypes.string,
  website: PropTypes.string
};

export default CollectionDetails;
