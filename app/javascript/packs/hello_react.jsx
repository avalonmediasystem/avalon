// Run this example by adding <%= javascript_pack_tag 'hello_react' %> to the head of your layout file,
// like app/views/layouts/application.html.erb. All it does is render <div>Hello React</div> at the bottom
// of the page.

import React from 'react';
import { createRoot } from "react-dom/client";
import PropTypes from 'prop-types';

const Hello = props => (
  <div>Hello {props.name}!</div>
);

Hello.defaultProps = {
  name: 'David'
};

Hello.propTypes = {
  name: PropTypes.string
};

const root = createRoot(document.body.appendChild(document.createElement('div')));
root.render(<Hello name="React" />);
