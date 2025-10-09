# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Setup

### Docker (Recommended)
- Use Docker Compose for development: `docker-compose up avalon worker`
- Create buckets first: `docker-compose run createbuckets`
- Copy config file: `cp config/controlled_vocabulary.yml.example config/controlled_vocabulary.yml`
- Access application at `localhost:3000`
- Attach to container for Rails debugging: `docker attach avalon_container_name`

### Test Environment
- Bring up test stack: `docker-compose up test`
- Run RSpec tests: `docker-compose exec test bash -c "bundle exec rspec"`
- Run individual specs: `docker-compose exec test bash -c "bundle exec rspec spec/path/to/spec.rb"`

### E2E Testing with Cypress
- Start development environment: `docker-compose up avalon`
- Create test users with rake tasks:
  - `docker-compose exec avalon bash -c "bundle exec rake avalon:user:create avalon_username=administrator@example.com avalon_password=password avalon_groups=administrator"`
  - Similar commands for manager@example.com and user@example.com
- Run Cypress: `docker-compose up cypress`
- Open Cypress interactively: `npm run cypress:open`

## Build Commands

### Ruby/Rails
- Install dependencies: `bundle install`
- Run development server: `bundle exec rake server:development`
- Run test server: `bundle exec rake server:test`
- Default rake task runs CI: `rake` (equivalent to `rake ci`)

### JavaScript
- Install JS dependencies: `yarn install`
- Webpack dev servers for specific components:
  - `npm run start-collection-index`
  - `npm run start-collection-view`
- ESLint for style checking: `eslint app/assets/javascripts/ --ext .js,.es6`
- Prettier for formatting: `prettier --write "app/assets/javascripts/path/*.es6"`

### Code Quality
- Use Bixby (Rubocop wrapper) for Ruby linting: `bundle exec bixby`

## Architecture Overview

### Core Models
- **MediaObject**: Central entity representing media items, includes WorkflowModelMixin, Hydra permissions, MODS metadata
- **MasterFile**: Represents individual media files, handles transcoding and derivatives
- **Collection**: Groups media objects, managed through Admin interface
- **Derivative**: Transcoded versions of master files at different qualities
- **Playlist/Timeline**: User-created collections and annotations

### Key Technologies
- **Rails 8.0** with ActiveFedora for Fedora repository integration
- **Samvera/Hydra** ecosystem for digital repository functionality
- **Sidekiq** for background job processing
- **React** components integrated via react-on-rails and Shakapacker
- **Fedora 6.5** for object storage with OCFL-S3 backend
- **Solr 9** for search and indexing
- **PostgreSQL** for relational data

### Media Processing
- **Active Encode** gem for transcoding orchestration
- **FFmpeg** for media processing operations
- **HLS.js** (custom fork) for media streaming
- **Video.js** for media player functionality

### Authentication & Authorization
- **Devise** with multiple strategies (Identity, LTI, SAML, LDAP)
- **Hydra::AccessControls** for object-level permissions
- Role-based access through groups and collections

### File Structure Patterns
- Models use extensive mixins for shared functionality
- Controllers follow standard Rails patterns with Blacklight integration
- JavaScript organized by functionality with webpack compilation
- React components for complex UI interactions

# Workflow
- First think through the problem, read the codebase for relevant files, and write a plan to tasks/todo.md.
- The plan should have a list of todo items that you can check off as you complete them
- Before you begin working, check in with me and I will verify the plan.
- Then, begin working on the todo items, marking them as complete as you go.
- Please every step of the way just give me a high level explanation of what changes you made
- Make every task and code change you do as simple as possible. We want to avoid making any massive or complex changes. Every change should impact as little code as possible. Everything is about simplicity.
- Be sure to typecheck when you’re done making a series of code changes
- Prefer running single tests, and not the whole test suite, for performance

Security prompt:
Please check through all the code you just wrote and make sure it follows security best practices. make sure there are no sensitive information in the front and and there are no vulnerabilities that can be exploited
