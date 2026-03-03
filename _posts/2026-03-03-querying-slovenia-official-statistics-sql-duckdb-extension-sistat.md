---
layout: post
title: "Querying Slovenia's Official Statistics (SURS, SiStat) in SQL"
subtitle: "Query Slovenian official statistics directly from DuckDB—no Python or external pipelines"
date: 2026-03-03 00:00:00
categories: [data-engineering, duckdb, sql, open-data]
tags: [duckdb, sistat, surs, slovenia, sql, px-web]
author: Florijan Klezin
excerpt: "A DuckDB extension that exposes Slovenia's SiStat (SURS) PX-Web API as three SQL table functions, so you can discover, inspect, and query Slovenian official statistics directly from DuckDB."
---

Slovenia's Statistical Office (SURS) publishes 1000+ datasets through the **SiStat** PX-Web API. Until recently, using that data in analytics meant custom scripts, ETL, or manual downloads.

> **A DuckDB extension** exposes SiStat as three SQL table functions—discover, inspect, and query Slovenian official statistics directly from DuckDB, with no Python or external pipelines.

---

## Why a DuckDB Extension?

DuckDB's extension API lets you add **table-valued functions**: they look like tables in SQL and can pull data from anywhere. For SiStat, that meant:

- **One environment**: analysts stay in DuckDB (and SQL) instead of switching to Python or R only to call the API.
- **Composable SQL**: `JOIN`, `WHERE`, `GROUP BY`, and materialization (`CREATE TABLE ... AS SELECT`) work immediately.
- **Consistency**: Same pattern as other "remote data" extensions (e.g. Eurostat), so the workflow is familiar.

The SiStat API is HTTP + JSON: a **table list** and **per-table metadata** via GET, and **dataset content** via POST in **JSON-stat** format. The extension's job is to wrap those calls into three table functions and return typed columns.

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

1. **Discover tables** — List datasets and filter by keyword (e.g. demographics, population):

```sql
SELECT title, table_id, updated
FROM SISTAT_Tables(language := 'en')
WHERE LOWER(title) LIKE '%demographics%'
ORDER BY updated DESC
LIMIT 5;
```

2. **Inspect structure (optional)** — See dimensions and value codes before reading data:

```sql
SELECT variable_code, variable_text, position, value_codes, value_texts
FROM SISTAT_DataStructure('05C1002S', language := 'en')
ORDER BY position;
```

3. **Query the data** — Use `SISTAT_Read` like a table; apply `WHERE` and `LIMIT` in SQL. Treat `NULL`, `''`, and `'-'` as missing; use `TRY_CAST(value AS DOUBLE)` for numeric analysis:

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
