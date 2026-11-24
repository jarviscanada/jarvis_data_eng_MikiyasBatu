-- Queries that help the Jarvis LCA team monitor the cluster.
-- Run with: psql -h localhost -U postgres -d host_agent -f sql/queries.sql

-- Helper function: round a timestamp down to the nearest 5-minute interval
-- e.g. 2026-11-23 17:43:21 -> 2026-11-23 17:40:00
CREATE OR REPLACE FUNCTION round5(ts TIMESTAMP) RETURNS TIMESTAMP AS
$$
BEGIN
RETURN date_trunc('hour', ts) + date_part('minute', ts)::INT / 5 * INTERVAL '5 min';
END;
$$
LANGUAGE PLPGSQL;


-- Query 1: Average memory usage per host, in 5-minute intervals
-- Shows how much memory each node used (as a percentage of its total memory),
-- so the LCA team can spot nodes that are running out of memory.
-- Note: total_mem is stored in KB and memory_free in MB, so total_mem is converted to MB.
SELECT
    u.host_id,
    round5(u.timestamp) AS timestamp,
    ROUND(AVG(((i.total_mem / 1024.0) - u.memory_free) / (i.total_mem / 1024.0) * 100), 2)
        AS avg_used_mem_percentage,
    i.hostname
FROM host_usage u
    JOIN host_info i ON u.host_id = i.id
GROUP BY u.host_id, i.hostname, round5(u.timestamp)
ORDER BY u.host_id, timestamp;


-- Query 2: Detect host failures
-- host_usage.sh runs every minute, so each node should report 5 times per
-- 5-minute interval. Fewer than 3 reports means the node (or its cron job) likely failed.
SELECT
    host_id,
    round5(timestamp) AS ts,
    COUNT(*) AS num_data_points
FROM host_usage
GROUP BY host_id, round5(timestamp)
HAVING COUNT(*) < 3
ORDER BY host_id, ts;