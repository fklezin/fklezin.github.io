---
layout: post
title:  "When to Consider Postgres Partitioning in 2026"
subtitle: "A practical guide to knowing when partitioning is the right call"
date:   2026-02-06 00:00:00
categories: [database, postgresql]
---

In 2026, PostgreSQL 17 and 18 have turned declarative partitioning into a mature, primary tool for managing high-velocity data. While standard B-tree indexes handle most datasets, you should implement partitioning when a table exceeds the **50–100 GB** threshold or **100 million rows**.

## Operational Signals for Partitioning

**Maintenance Fatigue** — When `VACUUM` or `REINDEX` operations exceed 30 minutes, partitioning allows the system to process smaller, individual chunks rather than the entire dataset.

<pre><code class="sql">-- Vacuum only the February 2024 partition
VACUUM ANALYZE events_2024_02;
</code></pre>

**The "O(1)" Cleanup** — Dropping or detaching a partition is a near-instant operation that avoids the "concurrency nightmare" and WAL bloat caused by deleting millions of rows.

<pre><code class="sql">-- Near-instant removal of data from the main table
ALTER TABLE events DETACH PARTITION events_2023_01;

-- Optional: Permanently delete the detached table
DROP TABLE events_2023_01;
</code></pre>

**Data Tiering** — You can use **Tablespaces** to pin "hot" data to NVMe storage while moving "cold" historical partitions to cheaper, slower media.

<pre><code class="sql">-- Place new "hot" data on high-speed NVMe storage
CREATE TABLE events_2026_01 PARTITION OF events
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01')
    TABLESPACE fast_nvme_drive;

-- Move "cold" historical data to cheaper, slower HDD storage
ALTER TABLE events_2024_01 SET TABLESPACE archival_storage;
</code></pre>

---

## Technical Performance Gains

### 1. Partition Pruning (Query Optimization)

Pruning allows the database to ignore partitions that cannot contain data relevant to the `WHERE` clause. By 2026, this logic is highly efficient for static, dynamic, and parameterised queries.

<pre><code class="sql">-- Basic Pruning: The planner skips all partitions except 'events_2024_03'
EXPLAIN ANALYZE
SELECT * FROM events
WHERE created_at >= '2024-03-01' AND created_at < '2024-04-01';

-- Execution-Time Pruning: Works with subqueries
-- where the value is unknown at planning
SELECT * FROM events
WHERE created_at = (SELECT current_period FROM system_status);

-- Parameterised Pruning: Pruning is applied when the parameter is supplied
PREPARE get_events(timestamp) AS
    SELECT * FROM events WHERE created_at = $1;
EXECUTE get_events('2024-03-15');
</code></pre>

### 2. Parallel Append (High-Throughput Analytics)

Parallel Append allows the database to distribute the workload of scanning multiple partitions across several CPU workers simultaneously. This is particularly effective for analytical queries spanning large time ranges.

<pre><code class="sql">-- High-Throughput Query: Scans multiple partitions in parallel
EXPLAIN ANALYZE
SELECT DATE_TRUNC('day', created_at) AS day, COUNT(*)
FROM events
WHERE created_at >= '2024-01-01' AND created_at < '2024-07-01'
GROUP BY 1;
</code></pre>

---

## The "Why Not" Constraints

Partitioning is not a default choice; it adds planning overhead and increases memory consumption for every session. Avoid it for:

### 1. Small Tables (<10 GB)

**Example:** A `settings` table with 50,000 rows.

At this size, the entire table and its indexes likely fit in memory. Partitioning would add "planning overhead" — making the database spend more time deciding which partitions to search than actually fetching the data. A standard B-tree index is significantly faster here.

### 2. OLTP Point Lookups

**Example:** Fetching a single user profile by email.

In high-concurrency Online Transaction Processing (OLTP) workloads, speed is about efficiency. A standard B-tree index on a single table handles these lookups perfectly. Partitioning adds a layer of "routing overhead" for every request, providing no benefit when you are only retrieving one record.

### 3. Missing Partition Keys

**Example:** You partition a `sales` table by `sale_date` (Range), but your most frequent query filters by `customer_id`.

Because the partition key (`sale_date`) is missing, the query planner cannot perform "pruning". It is forced to scan the index of every single partition in the system, which is much slower and more resource-intensive than scanning a single index on a non-partitioned table.

---

## References

- [How to Scale Tables with Time-Based Partitioning in PostgreSQL](https://oneuptime.com/blog/post/2026-01-26-time-based-partitioning-postgresql/view)
- [It's 2026, Just Use Postgres — Tiger Data](https://www.tigerdata.com/blog/its-2026-just-use-postgres)
- [PostgreSQL Partitioning: The Most Useful Feature You May Never Have Used](https://www.red-gate.com/simple-talk/databases/postgresql/postgresql-partitioning-the-most-useful-feature-you-may-never-have-used/)
- [PostgreSQL 18 Documentation: Table Partitioning](https://www.postgresql.org/docs/current/ddl-partitioning.html)
- [Scaling PostgreSQL to power 800 million ChatGPT users — OpenAI](https://openai.com/index/scaling-postgresql/)
- [When to Consider Postgres Partitioning — Tiger Data](https://www.tigerdata.com/learn/when-to-consider-postgres-partitioning)
