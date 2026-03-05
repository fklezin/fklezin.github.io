---
layout: post
title: "Querying Slovenia's Official Statistics (SURS, SiStat) in SQL"
subtitle: "Query SiStat directly from DuckDB with SQL-first workflows"
date: 2026-03-03 00:00:00
categories: [data-engineering, duckdb, sql, open-data]
tags: [duckdb, sistat, surs, slovenia, sql, px-web]
author: Florijan Klezin
excerpt: "A DuckDB extension that exposes Slovenia's SiStat (SURS) PX-Web API as SQL table functions, so you can discover datasets, inspect metadata, and query live data directly in DuckDB."
---

Slovenia's Statistical Office (SURS) publishes thousands of datasets through the **SiStat** PX-Web API. This extension brings that data directly into DuckDB, so you can stay in SQL instead of building separate API scripts.

The `sistat` extension exposes three table functions:

- `SISTAT_Tables(language := 'en')` for dataset discovery
- `SISTAT_DataStructure(table_id, language := 'en')` for metadata inspection
- `SISTAT_Read(table_id, language := 'en')` for querying dataset values

All functions support `language` (`'en'`, `'sl'`, ...). `table_id` works with or without a `.px` suffix.

## Installation

### Community extension (when available)

```sql
INSTALL sistat FROM community;
LOAD sistat;
```

### Build and load from source

```bash
git clone https://github.com/fklezin/duckdb-sistat
cd duckdb-sistat
make
```

Then load in DuckDB:

```sql
LOAD 'build/release/extension/sistat/sistat.duckdb_extension';
```

## Typical SQL Workflow

### 1. Discover datasets

```sql
SELECT title, table_id, updated
FROM SISTAT_Tables(language := 'en')
ORDER BY updated DESC
LIMIT 5;
```

Use `table_id` in scripts; titles can change.

### 2. Inspect table structure

```sql
SELECT variable_code, variable_text, position, value_codes, value_texts
FROM SISTAT_DataStructure('05C1002S', language := 'en')
ORDER BY position;
```

This helps you find valid filter values before reading a full dataset.

### 3. Query data directly

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

`value` is often text in PX datasets, so use `TRY_CAST` for numeric analysis.

### 4. Materialize a reproducible snapshot

```sql
CREATE OR REPLACE TABLE population_data AS
SELECT *
FROM SISTAT_Read('05C1002S', language := 'en')
WHERE value IS NOT NULL AND value <> '' AND value <> '-';

SELECT COUNT(*) AS loaded_rows FROM population_data;
```

SiStat queries return live data. Materialize local tables for repeatable downstream analysis.

## End-to-End Example

```sql
-- 1) Find a table
SELECT title, table_id
FROM SISTAT_Tables(language := 'en')
WHERE LOWER(title) LIKE '%population%'
LIMIT 1;

-- 2) Inspect dimensions
SELECT variable_code, variable_text
FROM SISTAT_DataStructure('05C1002S', language := 'en')
ORDER BY position;

-- 3) Materialize data
CREATE OR REPLACE TABLE population_data AS
SELECT *
FROM SISTAT_Read('05C1002S', language := 'en')
WHERE value IS NOT NULL AND value <> '' AND value <> '-';

-- 4) Analyze
SELECT
  "SPOL" AS sex_code,
  AVG(TRY_CAST(value AS DOUBLE)) AS avg_value
FROM population_data
GROUP BY 1
ORDER BY 1;
```

## Querying Tips

- Start with metadata (`SISTAT_Tables`, then `SISTAT_DataStructure`) before large reads.
- Filter early (`WHERE`) and limit exploratory pulls (`LIMIT`).
- Prefer explicit column selection for stable production queries.
- Treat `NULL`, `''`, and `'-'` as missing values.

## References

- [duckdb-sistat README](https://github.com/fklezin/duckdb-sistat/blob/main/README.md)
- [duckdb-sistat examples](https://github.com/fklezin/duckdb-sistat/tree/main/examples/queries)
- [SiStat (SURS) PX-Web](https://pxweb.stat.si/sistat/sl/Home/Help)
- [DuckDB Community Extensions](https://duckdb.org/docs/extensions/community_extensions.html)
