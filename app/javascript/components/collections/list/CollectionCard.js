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

import '../Collection.scss';
import PropTypes from 'prop-types';
import CollectionCardShell from '../CollectionCardShell';
import CollectionCardThumbnail from '../CollectionCardThumbnail';
import CollectionCardBody from '../CollectionCardBody';

const CollectionCard = ({ attributes, showUnit }) => {
  const unitName = attributes.description ? attributes.unit.substring(0, 30) : attributes.unit;
  const ellipsis = attributes.description ? <span>...</span> : null;
  return (
    <CollectionCardShell>
      <CollectionCardThumbnail>
        {attributes.poster_url && (
          <a href={attributes.url} aria-hidden="true" tabIndex="-1">
            <img src={attributes.poster_url} alt=""></img>
          </a>
        )}
      </CollectionCardThumbnail>
      <CollectionCardBody>
        <h4>
          <a href={attributes.url}>
            {attributes.name.substring(0, 50)}
            {attributes.name.length >= 50 && <span>...</span>}
          </a>
        </h4>
        <dl>
          { showUnit && <dt>Unit</dt> && 
            <dd className="italic">
              {unitName}
              {attributes.unit.length >= 30 && ellipsis}
            </dd>
          }
          {attributes.description && (
            <div>
              <dd>
                {attributes.description.substring(0, 100)}
                {attributes.description.length >= 100 && <span>...</span>}
              </dd>
            </div>
          )}
        </dl>
      </CollectionCardBody>
    </CollectionCardShell>
  );
};

CollectionCard.propTypes = {
  attributes: PropTypes.object,
  showUnit: PropTypes.bool
};

export default CollectionCard;
