import React from 'react';
import './Collection.scss';
import PropTypes from 'prop-types';

const CollectionCard = ({ attributes, showUnit }) => {
  return (
    <div className="collection-card panel panel-default">
      <div className="document-thumbnail">
        {attributes.poster_url && (
          <a href={attributes.url}>
            <img src={attributes.poster_url} alt="Collection thumbnail"></img>
          </a>
        )}
      </div>
      <div className="panel-body">
        <div className="collection-card-description">
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
        </div>
      </div>
    </div>
  );
};

CollectionCard.propTypes = {
  attributes: PropTypes.object,
  showUnit: PropTypes.bool
};

export default CollectionCard;
