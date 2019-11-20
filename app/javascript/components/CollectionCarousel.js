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
                className="img-responsive"
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
