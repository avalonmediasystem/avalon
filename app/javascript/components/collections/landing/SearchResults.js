/*
 * Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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
        <li key={doc.id} className="col-sm-3">
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
