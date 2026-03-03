---
layout: post
title: "Querying Slovenia's Official Statistics (SURS, SiStat) in SQL"
subtitle: "Discover, inspect, and query Slovenian official statistics directly from DuckDB—no Python or external pipelines"
date: 2026-03-03 00:00:00
categories: [data-engineering, duckdb, sql, open-data]
tags: [duckdb, sistat, surs, slovenia, sql, px-web]
author: Florijan Klezin
excerpt: "A DuckDB extension that exposes Slovenia's SiStat (SURS) PX-Web API as three SQL table functions, so you can discover, inspect, and query Slovenian official statistics directly from DuckDB."
---


Slovenia's Statistical Office (SURS) publishes 1000+ datasets through the **SiStat** PX-Web API. Until recently, using that data in analytics meant custom scripts, ETL, or manual downloads. I built a **DuckDB extension** that exposes SiStat as three SQL table functions, so you can discover, inspect, and query Slovenian official statistics directly from DuckDB—no Python or external pipelines.

---

## Why a DuckDB Extension?

DuckDB's extension API lets you add **table-valued functions**: they look like tables in SQL and can pull data from anywhere. For SiStat, that meant:

- **One environment**: analysts stay in DuckDB (and SQL) instead of switching to Python or R only to call the API.
- **Composable SQL**: `JOIN`, `WHERE`, `GROUP BY`, and materialization (`CREATE TABLE ... AS SELECT`) work immediately.
- **Consistency**: Same pattern as other "remote data" extensions (e.g. Eurostat), so the workflow is familiar.

The SiStat API is HTTP + JSON: a **table list** and **per-table metadata** via GET, and **dataset content** via POST in **JSON-stat** format. The extension's job is to wrap those calls into three table functions and return typed columns.

---

## What You Need to Implement the Wrappers

### 1. Three Table Functions, One API Shape

The PX-Web API has two kinds of endpoints:

- **Discovery and metadata**
  - List tables: `GET {base}/{lang}/Data/` → JSON array of `{ "text", "id", "updated" }`.
  - Table structure: `GET {base}/{lang}/Data/{table_id}.px` → JSON object with a `variables` array (code, text, values, valueTexts).

- **Data**
  - Same URL as structure, but **POST** with body
    `{"query":[],"response":{"format":"json-stat"}}`
    → JSON-stat document with `dataset.dimension` (id, size, category.index) and a flat `value` array.

So the extension needs three table functions:

| Function | Purpose | Binding behavior |
|----------|---------|------------------|
| `SISTAT_Tables(language)` | List datasets (title, table_id, updated, url) | No required args; optional `language`. In **Bind**, build list URL; in **Init**, GET and parse JSON array, fill state with rows. |
| `SISTAT_DataStructure(table_id, language)` | Dimensions, variable codes, value codes/texts | Required `table_id`; optional `language`. In **Bind**, GET metadata URL, parse `variables`, define columns (e.g. variable_code, variable_text, position, value_codes, value_texts). In **Init**, same GET, store variable rows in state. |
| `SISTAT_Read(table_id, language)` | The actual dataset | Required `table_id`. In **Bind**, GET metadata to learn dimension names and declare one column per dimension plus `value`. In **Init**, POST with JSON-stat request body, parse response, flatten the cube into rows. |

Each function follows the same DuckDB pattern: **Bind** (declare return types and do any one-off HTTP needed for schema), **Init** (fetch data and fill global state), **Execute** (stream from state into `DataChunk`s).

### 2. Parsing JSON and JSON-stat

- **Table list and metadata** are plain JSON objects/arrays; I used **yyjson** (already available in the DuckDB extension ecosystem) to walk the tree and read strings/numbers.
- **Data** is JSON-stat: a multi-dimensional cube. The response has `dataset.dimension.id` (dimension names), `dimension.size` (length per dimension), and for each dimension an entry in `dimension.{id}` with `category.index` mapping code → position. The `value` array is a single flat array in row-major order. So in **Init** you:
  - Compute strides from `size`;
  - For each linear index, compute the multi-dimensional index and look up the dimension labels from `category.index`;
  - Push one row per cell (dimension columns + value). Statistical symbols like `"-"`, `"..."`, `"z"` can be kept as strings and documented so users can filter or cast with `TRY_CAST(value AS DOUBLE)`.

Handling missing or non-numeric values in the **Execute** phase is just passing through strings; the SQL layer can do `WHERE value IS NOT NULL AND value <> '' AND value <> '-'` and `TRY_CAST(value AS DOUBLE)`.

### 3. HTTP and Dependencies

The extension uses DuckDB's built-in **HTTP** support (`HttpRequest::ExecuteHttpRequest`, `HttpSettings` from the context) so no extra HTTP client is needed. It only needs to build the correct URLs (e.g. `https://pxweb.stat.si/SiStatData/api/v1/{lang}/Data/{table_id}.px`), send GET for metadata and POST for data, and parse the body with yyjson. OpenSSL is required for HTTPS; the project links it via CMake.

### 4. Normalizing the Table ID

The API expects table identifiers with a `.px` suffix. The extension normalizes so callers can pass either `'05C1002S'` or `'05C1002S.px'`; a small helper strips or appends `.px` so the URL is always correct.

---

## Publishing as a DuckDB Community Extension

Once the extension builds and runs locally, publishing it so users can run `INSTALL sistat FROM community` is straightforward.

### Build and CI

- Start from DuckDB's **extension template** (or a fork). The template gives you CMake, vcpkg, and GitHub Actions that build for Linux, macOS, Windows, and Wasm.
- Your extension must build with DuckDB's **CI toolchain** ([extension-ci-tools](https://github.com/duckdb/extension-ci-tools)). The template is already set up for this, so if it builds in the template, it will build in the community repo.

### Submitting to the Community Repository

1. Open a **Pull Request** in [duckdb/community-extensions](https://github.com/duckdb/community-extensions).
2. Add a **descriptor file** under `extensions/sistat/description.yml` (or the name of your extension). Existing extensions in that repo are the best reference.

Example shape:

```yaml
extension:
  name: sistat
  description: Query Slovenia's SiStat (SURS PX-Web API) open data directly from DuckDB with SQL.
  version: 0.0.1
  language: C++
  build: cmake
  license: MIT
  maintainers:
    - fklezin

repo:
  github: fklezin/duckdb-sistat
  ref: <commit-hash>

docs:
  hello_world: |
    SELECT title, table_id, updated
    FROM SISTAT_Tables(language := 'en')
    WHERE LOWER(title) LIKE '%demographics%'
    ORDER BY updated DESC
    LIMIT 5;

    SELECT variable_code, variable_text, position, value_codes, value_texts
    FROM SISTAT_DataStructure('05C1002S', language := 'en')
    ORDER BY position;

    SELECT * FROM SISTAT_Read('05C1002S', language := 'en') LIMIT 10;
  extended_description: |
    The sistat extension integrates the Statistical Office of the Republic of Slovenia (SURS) SiStat PX-Web API into DuckDB...
```

3. The **ref** should point to a commit that builds with the current DuckDB version used by the community repo. CI will build your extension for all platforms; once the PR is merged, the extension becomes installable via `INSTALL ... FROM community`.

---

## How to Use It

### Installation

**From the DuckDB Community Repository (recommended):**

```sql
INSTALL sistat FROM community;
LOAD sistat;
```

**From source:**

```bash
git clone https://github.com/fklezin/duckdb-sistat
cd duckdb-sistat
make
```

Then in DuckDB:

```sql
LOAD 'build/release/extension/sistat/sistat.duckdb_extension';
```

### Typical Workflow

1. **Discover tables** — List datasets and filter by keyword (e.g. demographics, population).

```sql
SELECT title, table_id, updated
FROM SISTAT_Tables(language := 'en')
WHERE LOWER(title) LIKE '%demographics%'
ORDER BY updated DESC
LIMIT 5;
```

2. **Inspect structure (optional)** — See dimensions and value codes before reading data.

```sql
SELECT variable_code, variable_text, position, value_codes, value_texts
FROM SISTAT_DataStructure('05C1002S', language := 'en')
ORDER BY position;
```

3. **Query the data** — Use `SISTAT_Read` like a table; apply `WHERE` and `LIMIT` in SQL. Treat `NULL`, `''`, and `'-'` as missing; use `TRY_CAST(value AS DOUBLE)` for numeric analysis.

```sql
SELECT
  "KOHEZIJSKA REGIJA",
  "STAROST",
  "POLLETJE",
  "SPOL",
  TRY_CAST(value AS DOUBLE) AS value_num
FROM SISTAT_Read('05C1002S', language := 'en')
WHERE value IS NOT NULL AND value <> '' AND value <> '-'
LIMIT 500;
```

For a reproducible snapshot:

```sql
CREATE TABLE population_snapshot AS
SELECT CURRENT_TIMESTAMP AS snapshot_ts, *
FROM SISTAT_Read('05C1002S', language := 'en');
```

All functions accept an optional `language` argument (e.g. `'en'`, `'sl'`). Table IDs can be passed with or without the `.px` suffix. Data is fetched live from the official API; for reproducible results, materialize into a local table.

---

## References

- [SiStat (SURS) PX-Web](https://pxweb.stat.si/sistat/sl/Home/Help) — Official Slovenian statistics portal and API.
- [DuckDB Community Extensions](https://duckdb.org/docs/extensions/community_extensions.html) — Overview and installation.
- [Community Extension Development](https://duckdb.org/community_extensions/development) — Building and publishing.
- [duckdb/community-extensions](https://github.com/duckdb/community-extensions) — Repository and descriptor examples.
- [duckdb/extension-template](https://github.com/duckdb/extension-template) — C++ extension template and CI.
- [duckdb-sistat](https://github.com/fklezin/duckdb-sistat) — Source of the sistat extension.
