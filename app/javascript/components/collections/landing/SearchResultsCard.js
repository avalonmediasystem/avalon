import React from 'react';
import PropTypes from 'prop-types';

const CardMetaData = ({ doc, fieldLabel, fieldName }) => {
  if (doc[fieldName]) {
    return (
      <>
        <dt>{fieldLabel}</dt>
        {Array.isArray(doc[fieldName]) && doc[fieldName].length > 1 ? (
          <dd>{doc[fieldName].join(', ')}</dd>
        ) : (
          <dd>{doc[fieldName]}</dd>
        )}
      </>
    );
  }
  return null;
};

CardMetaData.propTypes = {
  doc: PropTypes.object,
  fieldLabel: PropTypes.string,
  fieldName: PropTypes.string
};

const millisecondsToFormattedTime = ms => {
  let sec_num = ms / 1000;
  let hours = Math.floor(sec_num / 3600);
  let minutes = Math.floor((sec_num % 3600) / 60);
  let seconds = sec_num - minutes * 60 - hours * 3600;

  let hourStr = hours < 10 ? `0${hours}` : `${hours}`;
  let minStr = minutes < 10 ? `0${minutes}` : `${minutes}`;
  let secStr = seconds.toFixed(0);
  secStr = seconds < 10 ? `0${secStr}` : `${secStr}`;

  return `${hourStr}:${minStr}:${secStr}`;
};

const duration = ms => {
  if (Number(ms) > 0) { return millisecondsToFormattedTime(ms) }
};

const thumbnailSrc = (doc, props) => {
  if (doc['section_id_ssim']) { return `${props.baseUrl}/master_files/${props.doc['section_id_ssim'][0]}/thumbnail` }
};

const SearchResultsCard = (props) => {
  const { baseUrl, index, doc } = props;
  return (
    <li key={index} className="search-within-search-result col-sm-4">
      <div className="panel panel-default">
        <div className="document-thumbnail">
          <span className="timestamp badge badge-dark">{duration(doc['duration_ssi'])}</span>
          <a href={baseUrl + '/media_objects/' + doc['id']}>{thumbnailSrc(doc, props) && (
            <img className="card-img-top img-cover" src={thumbnailSrc(doc, props)} alt="Card image cap" /> )}
          </a>
        </div>
        <div className="panel-body description">
          <h4><a href={baseUrl + '/media_objects/' + doc['id']}>{doc['title_tesi'] || doc['id']}</a></h4>
          <dl id={'card-body-' + index} className="card-text dl-horizontal">
            <CardMetaData doc={doc} fieldLabel="Date" fieldName="date_ssi" />
            <CardMetaData doc={doc} fieldLabel="Main Contributors" fieldName="creator_ssim" />
            <CardMetaData doc={doc} fieldLabel="Summary" fieldName="summary_ssi" />
          </dl>
        </div>
      </div>
    </li>
  );
};

SearchResultsCard.propTypes = {
  baseUrl: PropTypes.string,
  index: PropTypes.number,
  doc: PropTypes.object
};

export default SearchResultsCard;
