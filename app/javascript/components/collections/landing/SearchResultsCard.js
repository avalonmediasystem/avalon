/* 
 * Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

import React from 'react';
import PropTypes from 'prop-types';
import CollectionCardShell from '../CollectionCardShell';
import CollectionCardThumbnail from '../CollectionCardThumbnail';
import CollectionCardBody from '../CollectionCardBody';

const CardMetaData = ({ doc, fieldLabel, fieldName }) => {
  let metaData = null;
  let value = doc.attributes[fieldName]?.attributes?.value;
  if (Array.isArray(value) && value.length > 1) {
    metaData = value.join(', ');
  } else if (typeof value == 'string') {
    const summary = value.substring(0, 50);
    metaData = value.length >= 50 ? `${summary}...` : value;
  } else {
    metaData = value;
  }

  if (doc.attributes[fieldName]) {
    return (
      <React.Fragment>
        <dt className='col-sm-5'>{fieldLabel}</dt>
        <dd className='col-sm-7'>{metaData}</dd>
      </React.Fragment>
    );
  }
  return null;
};

CardMetaData.propTypes = {
  doc: PropTypes.object,
  fieldLabel: PropTypes.string,
  fieldName: PropTypes.string
};

const millisecondsToFormattedTime = sec_num => {
  let tostring = num => {
    return `0${num}`.slice(-2);
  };
  let hours = Math.floor(sec_num / 3600);
  let minutes = Math.floor((sec_num % 3600) / 60);
  let seconds = sec_num - minutes * 60 - hours * 3600;
  return `${tostring(hours)}:${tostring(minutes)}:${tostring(
    seconds.toFixed(0)
  )}`;
};

const duration = ms => {
  if (Number(ms) > 0) {
    return millisecondsToFormattedTime(ms / 1000);
  }
};

const thumbnailSrc = (doc, props) => {
  if (doc.attributes['section_id_ssim']) {
    return `${props.baseUrl}master_files/${doc.attributes['section_id_ssim'].attributes.value[0]}/thumbnail`;
  }
};

const SearchResultsCard = props => {
  const { baseUrl, index, doc } = props;
  return (
    <CollectionCardShell>
      <CollectionCardThumbnail>
        <span className="timestamp badge badge-dark">
          {duration(doc.attributes['duration_ssi'].attributes.value)}
        </span>
        <a href={baseUrl + 'media_objects/' + doc['id']}>
          {thumbnailSrc(doc, props) && (
            <img
              className="card-img-top img-cover"
              src={thumbnailSrc(doc, props)}
              alt="Card image cap"
            />
          )}
        </a>
      </CollectionCardThumbnail>
      <CollectionCardBody>
        <>
          <h4>
            <a href={baseUrl + 'media_objects/' + doc['id']}>
              { doc.attributes['title_tesi'] && doc.attributes['title_tesi'].attributes.value.substring(0, 50) || doc['id'] }
              { doc.attributes['title_tesi'] && doc.attributes['title_tesi'].attributes.value.length >= 50 && <span>...</span> }
            </a>
          </h4>
          <dl id={'card-body-' + index} className="card-text row">
            <CardMetaData doc={doc} fieldLabel="Date" fieldName="date_ssi" />
            <CardMetaData
              doc={doc}
              fieldLabel="Main Contributors"
              fieldName="creator_ssim"
            />
            <CardMetaData
              doc={doc}
              fieldLabel="Summary"
              fieldName="summary_ssi"
            />
          </dl>
        </>
      </CollectionCardBody>
    </CollectionCardShell>
  );
};

SearchResultsCard.propTypes = {
  baseUrl: PropTypes.string,
  index: PropTypes.number,
  doc: PropTypes.object
};

export default SearchResultsCard;
