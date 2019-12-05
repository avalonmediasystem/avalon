import React from 'react';
import '../Collection.scss';
import SearchResultsCard from './SearchResultsCard';
import CollectionFilterNoResults from '../CollectionsFilterNoResults';
import PropTypes from 'prop-types';

const SearchResults = ({ documents = [], baseUrl }) => {
  if (documents.length === 0)
    return (
      <div style={{ paddingTop: '3rem' }}>
        <CollectionFilterNoResults />
      </div>
    );

  return (
    <ul className="row list-unstyled search-within-search-results">
      {documents.map((doc, index) => (
        <li key={doc.id} className="col-sm-4">
          <SearchResultsCard doc={doc} index={index} baseUrl={baseUrl} />
        </li>
      ))}
    </ul>
  );
};

SearchResults.propTypes = {
  documents: PropTypes.array,
  baseUrl: PropTypes.string
};

export default SearchResults;
