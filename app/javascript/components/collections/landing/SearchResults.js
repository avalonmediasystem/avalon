import React from 'react';
import '../Collection.scss';
import SearchResultsCard from './SearchResultsCard';

const SearchResults = props => {
  return (
    <ul className="search-within-search-results">
      {props.documents.map((doc, index) => (
        <SearchResultsCard
          key={index}
          doc={doc}
          index={index}
          baseUrl={props.baseUrl}
        />
      ))}
    </ul>
  );
};

export default SearchResults;
