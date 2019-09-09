import React from 'react';
import { render } from 'react-dom';
import Search from './Search';

const props = {
  baseUrl: "https://spruce.dlib.indiana.edu",
  collection: "Chris Test"
};

render(<Search {...props} />, document.getElementById('root'));