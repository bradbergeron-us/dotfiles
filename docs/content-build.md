# content-build Development Guide

## Overview

content-build is the static content generator for VA.gov. It builds HTML pages from Liquid templates and Drupal content, and serves them alongside the vets-website application bundles.

## Repository

- **Location**: `~/Code/va.gov/content-build`
- **GitHub**: https://va.ghe.com/software/content-build
- **Main Branch**: `main`
- **Port**: 3002 (dev server)

## Quick Start

### Using the Startup Script

The easiest way to get content-build running:

```bash
content-build-start
```

Or run the script directly:

```bash
bash ~/dotfiles/scripts/content-build/start-content-build.sh
```

This script will:
1. Pull latest changes from `main` branch (if no uncommitted changes)
2. Prompt for optional branch checkout
3. Install dependencies via jfrog proxy using `yarn install-safe`
4. Optionally fetch latest Drupal content cache from S3
5. Start the watch server (builds and serves content, watches for changes)
6. Open a new Hyper tab with the watch server running

### Manual Startup

If you prefer to start manually:

```bash
cd ~/Code/va.gov/content-build
yarn install-safe
yarn watch
```

The site will be available at http://localhost:3002

## Key Commands

### Building Content

```bash
# Build all content once (no watch)
yarn build

# Build and watch for changes (also serves)
yarn watch

# Serve already-built content without watching
yarn serve

# Preview mode (adds routes for previewing Drupal nodes)
yarn preview
```

### Content Cache

```bash
# Fetch latest content cache from S3 (faster than pulling from Drupal)
yarn fetch-drupal-cache

# Build with fresh content from Drupal (requires local VA CMS)
yarn build --pull-drupal

# Build with cached assets (skip downloading assets)
yarn build --pull-drupal --use-cached-assets
```

### Testing

```bash
# Run all unit tests
yarn test:unit

# Run specific test file
yarn test:unit src/site/filters/liquid.unit.spec.js

# Run tests in watch mode
yarn test:watch

# Run Cypress E2E tests
yarn cy:open   # Opens Cypress UI
yarn cy:run    # Runs tests headlessly
```

### Linting

```bash
# Run all linters
yarn lint

# Run JavaScript linter
yarn lint:js

# Auto-fix linting issues
yarn lint:js:fix

# Lint only changed files
yarn lint:changed
```

## Architecture

### How content-build Works

1. **Metalsmith Pipeline**: Uses Metalsmith to process templates and content
2. **Liquid Templates**: Templates are written in Liquid (similar to Shopify's template language)
3. **Drupal Content**: Fetches content from VA CMS (Drupal) via GraphQL
4. **Static HTML**: Generates static HTML pages from templates + content
5. **Symlink to vets-website**: Creates symlink to vets-website app bundles for integration

### Directory Structure

```
content-build/
├── src/
│   ├── applications/        # Application registry and configurations
│   ├── site/
│   │   ├── stages/          # Build pipeline stages
│   │   │   ├── build/       # Build-time processing
│   │   │   │   └── drupal/  # Drupal content queries
│   │   │   └── html/        # HTML generation
│   │   ├── layouts/         # Page layout templates (Liquid)
│   │   ├── includes/        # Reusable template partials
│   │   ├── filters/         # Custom Liquid filters
│   │   └── paragraphs/      # Drupal paragraph templates
│   ├── platform/            # Shared platform code
│   └── js/                  # JavaScript for static pages
├── script/                  # Build and utility scripts
├── config/                  # Webpack and environment configs
├── .cache/                  # Cached Drupal content (gitignored)
└── build/                   # Output directory (gitignored)
```

## Configuration

### Environment Variables (.env file)

content-build uses a `.env` file for Drupal configuration:

```bash
# Copy example file
cp .env.example .env

# Edit with your settings
DRUPAL_ADDRESS=https://cms-8ry6zt2asg946vdfuiryyamuc9gkuyzc.demo.cms.va.gov/
DRUPAL_USERNAME=content_build_api
DRUPAL_PASSWORD=drupal8
```

**Note**: For production CMS access, request credentials in [#cms-support](https://dsva.slack.com/archives/CDHBKAL9W)

### Build Optimization

Building all content can take 8+ hours. To speed up local development:

1. **Comment out unused content types** in `src/site/stages/build/drupal/individual-queries.js`:

```javascript
function getNodeQueries(entityCounts) {
  return {
    ...getNodePageQueries(entityCounts),
    GetNodeLandingPages,
    GetCampaignLandingPages,
    GetNodeBasicLandingPage,
    // Comment out content types you don't need:
    // ...getNodeVaFormQueries(entityCounts),
    // ...getNodeHealthCareRegionPageQueries(entityCounts),
    // ...getNewsStoryQueries(entityCounts),
    // ...getNodeEventQueries(entityCounts),
    // etc.
  };
}
```

2. **Skip asset downloads** by commenting out in `src/site/stages/build/index.js`:

```javascript
// smith.use(downloadDrupalAssets(BUILD_OPTIONS), 'Download Drupal assets');
```

3. **Clear cache** and rebuild:

```bash
rm -rf .cache/localhost/drupal/pages.json
yarn build --pull-drupal && yarn watch
```

## Integration with vets-website

content-build creates a symlink to vets-website's built applications:

```
content-build/build/localhost/generated → vets-website/build/localhost/generated
```

This allows content-build to serve both:
- Static content pages (from templates)
- Application bundles (from vets-website)

**Important**: Make sure vets-website is built before running content-build if you need to test applications.

## Common Tasks

### Working on a Feature Branch

The startup script handles branch switching:

```bash
content-build-start
# → Prompts: "Run watch server on a different branch? (y/N):"
# → Enter: y
# → Enter branch name: feature/my-feature
```

Or manually:

```bash
cd ~/Code/va.gov/content-build
git checkout feature/my-feature
git pull origin feature/my-feature
yarn watch
```

### Testing Template Changes

1. Start watch server: `yarn watch`
2. Edit Liquid templates in `src/site/layouts/` or `src/site/includes/`
3. Watch server automatically rebuilds on template changes
4. Refresh browser at http://localhost:3002 to see changes

### Testing with Fresh Drupal Content

```bash
# Ensure local VA CMS is running
yarn build --pull-drupal

# Then start watch server
yarn watch
```

### Running with vets-website

For full integration testing:

```bash
# Terminal 1: Start vets-website
cd ~/Code/va.gov/vets-website
yarn watch --entry=your-app

# Terminal 2: Start content-build
cd ~/Code/va.gov/content-build
yarn watch

# Or use the all-in-one script:
vets-start-all  # Starts vets-api, vets-website, and content-build
```

## Troubleshooting

### Build Fails with Template Error

If markdown file exists in `vagov-content` but template is deleted:

```bash
cd ~/Code/va.gov/vagov-content
git pull origin main
cd ~/Code/va.gov/content-build
yarn build
```

### Port 3002 Already in Use

```bash
# Find and kill the process
lsof -ti:3002 | xargs kill -9

# Or use a different port
yarn serve --port 3003
```

### Symlink to vets-website Not Working

```bash
# content-build creates symlink automatically, but you can recreate it:
cd ~/Code/va.gov/content-build/build/localhost
rm -f generated
ln -s ../../../vets-website/build/localhost/generated generated
```

### Drupal Content Not Loading

1. Check `.env` file exists and has valid credentials
2. Fetch latest cache: `yarn fetch-drupal-cache`
3. Or rebuild from Drupal: `yarn build --pull-drupal`

### Out of Memory During Build

The build uses high memory limits. If you still run out:

```bash
# Increase Node memory limit (default is 12288 MB)
node --max-old-space-size=16384 --expose-gc script/build-content.js
```

## Useful Resources

### Documentation

- [Platform Docs](https://depo-platform-documentation.scrollhelp.site/developer-docs/)
- [Setting up local frontend environment](https://depo-platform-documentation.scrollhelp.site/developer-docs/Setting-up-your-local-frontend-environment.1844215878.html)
- [GitHub Codespaces Guide](https://depo-platform-documentation.scrollhelp.site/developer-docs/Using-GitHub-Codespaces.1909063762.html)

### Slack Channels

- **#vfs-platform-support** - General platform questions
- **#cms-support** - Drupal/CMS questions
- **#vets-website** - Frontend questions
- **#content-build** - content-build specific questions

## Node & Yarn Versions

```json
{
  "engines": {
    "node": ">=22.22.0",
    "yarn": "1.19.1"
  }
}
```

### Version Management

If you need to switch Node versions:

```bash
# Using nvm
nvm use 22

# Or install specific version
nvm install 22.22.0
nvm use 22.22.0
```

## Git Workflow

### Creating a Feature Branch

```bash
cd ~/Code/va.gov/content-build
git checkout main
git pull origin main
git checkout -b feature/my-feature-name

# Make changes, commit, push
git add .
git commit -m "Description of changes"
git push origin feature/my-feature-name
```

### Pull Request

```bash
# After pushing your branch
gh pr create --title "Your PR title" --body "Description"

# Or create PR on GitHub
open https://va.ghe.com/software/content-build/compare
```

## Related Repositories

- **vets-website**: React applications (`~/Code/va.gov/vets-website`)
- **vets-api**: Rails API backend (`~/Code/va.gov/vets-api`)
- **vagov-content**: Markdown content (`~/Code/va.gov/vagov-content`)
- **va.gov-cms**: Drupal CMS (separate infrastructure)

## Aliases & Scripts

All VA.gov startup scripts are located in `~/dotfiles/scripts/`:

```bash
# Start individual services
content-build-start   # Start content-build
vets-start           # Start vets-website
vets-api-start       # Start vets-api

# Start all services at once
vets-start-all       # Starts vets-api + vets-website + content-build
```

## Performance Tips

1. **Use content cache**: `yarn fetch-drupal-cache` is much faster than pulling from Drupal
2. **Optimize queries**: Comment out unused content types in `individual-queries.js`
3. **Skip assets**: Comment out `downloadDrupalAssets` for faster builds
4. **Incremental builds**: Use `yarn watch` for live reload instead of full rebuilds
5. **Limit scope**: Only build the content types you're actively working on

## Production Builds

Building for production environments:

```bash
# Build for staging
yarn build --buildtype=vagovstaging

# Build for production
NODE_ENV=production yarn build --buildtype=vagovprod
```

**Note**: Production builds disable dev features and enable optimizations.
