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

/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

// console.log('Hello World from Webpacker')
// Support component names relative to this directory:

/* 
 * For some reason including the `embeds` directory in this `require.context` breaks
 * the player. Filtering out the directory allows everything to operate as intended.
 */

import ReactOnRails from 'react-on-rails';

import CollectionList from '../components/CollectionList';
import CollectionCarousel from '../components/CollectionCarousel';
import CollectionDetails from '../components/CollectionDetails';
import Search from '../components/Search';
import MediaObjectRamp from '../components/MediaObjectRamp';
import ReactButtonContainer from '../components/ReactButtonContainer';
import PlaylistRamp from '../components/PlaylistRamp';
import IndexTable from '../components/tables/IndexTable';
import '../auto-complete-open.js';
import '@github/auto-complete-element';

ReactOnRails.register({
  CollectionList,
  CollectionCarousel,
  CollectionDetails,
  Search,
  MediaObjectRamp,
  ReactButtonContainer,
  PlaylistRamp,
  IndexTable
});
