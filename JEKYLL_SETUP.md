# Jekyll Local Development Setup

## 🐳 Docker Setup (Recommended)

The easiest way to run Jekyll locally without dealing with Ruby version issues:

```bash
docker-compose up
```

Your site will be available at http://localhost:4000

**Prerequisites:** Install [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop)

## Stopping the Server

```bash
docker-compose down
```

## What's included

- Jekyll 4.x
- kramdown-parser-gfm (GitHub Flavored Markdown)
- webrick (required for Ruby 3.x)
- jekyll-sass-converter 2.0 (for SCSS compilation)


