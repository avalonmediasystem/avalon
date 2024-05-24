/* 
 * Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

context('Navigations', () => {

  // checks navigation to Browse
  it('.browse_navigation()', () => {
		cy.login('administrator')
		cy.visit('/')
		cy.contains('Browse').click()
  })

  // checks navigation to Manage content
  it('.manage_content()', () => {
		cy.login('administrator')
		cy.visit('/')
		cy.contains('Manage Content')//.click()
		cy.contains('Manage').click()
		cy.visit('/admin/collections')
		cy.contains('Skip to main content')
		cy.contains('Create Collection')
		// What if there are no collections yet?
		cy.contains('Title')
		cy.contains('Items')
		cy.contains('Managers')
		cy.contains('Description')
		cy.contains('My Collections')
  })

  // checks naviagtion to Manage Groups
  it('.manage_groups()', () => {
		cy.login('administrator')
		cy.visit('/')
		cy.contains('Manage Groups')//.click()
		cy.contains('Manage').click()
		cy.visit('/admin/groups')
		cy.contains('System Groups')
		cy.contains('Additional Groups')
		cy.contains('Group Name')
		cy.contains('group_manager')
		cy.contains('administrator')
		cy.contains('manager')
  })

  // checks naviagtion to Playlist
  it('.playlists()', () => {
		cy.login('administrator')
		cy.visit('/')
		cy.contains('Playlists').click()
		cy.contains('Playlists')
		cy.contains('Create New Playlist')
  })

  // is able to sign out
  it('.signout()', () => {
		cy.login('administrator')
		cy.visit('/')
		cy.contains('Sign out').click()
  })

  // Search - is able to enter keyword and perform search
  it('.search()', () => {
		cy.visit('/')
		cy.get("li[class='nav-item'] a[class='nav-link']").click()
		cy.get("input.global-search-input[placeholder='Search this site']").first().type('lunchroom').should('have.value', 'lunchroom') // Only yield inputs within form
		cy.get('button.global-search-submit').first().click()
  })
})
