import React from 'react';
import '../Collection.scss';
import SearchResultsCard from './SearchResultsCard';

const SearchResults = props => {
  return (
    <ul className="search-within-search-results">
      {props.documents.map((doc, index) => (
        <SearchResultsCard
          key={doc['id']}
          doc={doc}
          index={index}
          baseUrl={props.baseUrl}
        />
      ))}
    </ul>
  );
};

export default SearchResults;
