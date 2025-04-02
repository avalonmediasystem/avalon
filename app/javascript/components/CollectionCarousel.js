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

import React, { useEffect, useState } from 'react';
import axios from 'axios';

const CollectionCarousel = ({ baseUrl }) => {
  const [collections, setCollections] = useState([]);

  useEffect(() => {
    getCollections();
  }, []);

  const getCollections = async () => {
    try {
      const response = await axios.get(baseUrl);
      setCollections(response.data);
    } catch (e) {
      console.log('Error retrieving collections from home splash page', e);
    }
  };

  return collections.length > 0 ? (
    <ul className="collection-carousel">
      {collections.map(collection => {
        const { id, url, poster_url, name } = collection;

        return (
          <li key={id}>
            <a href={url}>
              <img
                src={poster_url}
                alt={`${name} Collection thumbnail`}
                className="img-fluid"
              />
              <p className="collection-carousel-item-title">{name}</p>
            </a>
          </li>
        );
      })}
    </ul>
  ) : null;
};

export default CollectionCarousel;
