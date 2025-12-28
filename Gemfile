# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# Use modern Jekyll instead of github-pages to avoid eventmachine issues
gem "jekyll", "~> 4.0"
# Use sassc instead of sass-embedded to avoid "Broken pipe" error in Docker
gem "jekyll-sass-converter", "~> 2.0"
# jekyll-admin requires eventmachine, so it's commented out
# Uncomment if you need the admin interface and can resolve eventmachine compilation
# gem "jekyll-admin", group: :jekyll_plugins
gem "kramdown-parser-gfm"
gem "webrick", "~> 1.8"

# GitHub Pages compatible plugins (if needed for deployment)
# gem "github-pages", group: :jekyll_plugins
