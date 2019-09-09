import React from 'react';
import { render } from 'react-dom';
import CollectionList from './CollectionList';

const props = {
  baseUrl: "https://spruce.dlib.indiana.edu/collections.json"
  // filter: 'Good Morning Dave'
};

render(<CollectionList {...props} />, document.getElementById('root'));