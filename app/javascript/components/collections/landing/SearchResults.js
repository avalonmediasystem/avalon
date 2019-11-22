import React from 'react';
import '../Collection.scss';
import SearchResultsCard from './SearchResultsCard';

const SearchResults = props => {
  return (
    <ul className="row list-unstyled search-within-search-results">
      {props.documents.map((doc, index) => (
        <li key={doc.id} className="col-sm-4">
          <SearchResultsCard doc={doc} index={index} baseUrl={props.baseUrl} />
        </li>
      ))}
    </ul>
  );
};

export default SearchResults;
