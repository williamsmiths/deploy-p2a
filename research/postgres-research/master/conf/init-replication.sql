-- Initialize replication user (runs only on first DB initialization)
DO
$$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = 'replicator'
  ) THEN
    CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'p2a_research_replicator';
  END IF;
END;
$$;
