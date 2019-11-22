import React from 'react';
import '../Collection.scss';
import PropTypes from 'prop-types';
import CollectionCardShell from '../CollectionCardShell';
import CollectionCardThumbnail from '../CollectionCardThumbnail';
import CollectionCardBody from '../CollectionCardBody';

const CollectionCard = ({ attributes, showUnit }) => {
  return (
    <CollectionCardShell>
      <CollectionCardThumbnail>
        {attributes.poster_url && (
          <a href={attributes.url}>
            <img src={attributes.poster_url} alt="Collection thumbnail"></img>
          </a>
        )}
      </CollectionCardThumbnail>
      <CollectionCardBody>
        <h4>
          <a href={attributes.url}>{attributes.name}</a>
        </h4>
        <dl>
          {showUnit && <dt>Unit</dt> && <dd>{attributes.unit}</dd>}
          {attributes.description && (
            <div>
              <dd>
                {attributes.description.substring(0, 200)}
                {attributes.description.length >= 200 && <span>...</span>}
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
