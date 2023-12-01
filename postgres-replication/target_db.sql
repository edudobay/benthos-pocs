-- CREATE DATABASE dbtarget;

CREATE TABLE IF NOT EXISTS statements (
  id bigserial primary key,
  "sql" text not null,
  created_at timestamptz not null default current_timestamp
);

CREATE OR REPLACE FUNCTION perform_database_operation(
    IN operation_type VARCHAR(10),
    IN table_name VARCHAR(100),
    IN payload JSONB,
    IN primary_key JSONB DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    sql_query TEXT;
BEGIN
    -- Ensure that the operation_type is valid
    IF operation_type NOT IN ('INSERT', 'UPDATE', 'DELETE') THEN
        RAISE EXCEPTION 'Invalid operation type: %', operation_type;
    END IF;

    -- Construct the SQL query based on the operation type
    CASE operation_type
        WHEN 'INSERT' THEN
            sql_query := 'INSERT INTO ' || table_name || ' (' ||
                          (SELECT STRING_AGG(key, ', ') FROM jsonb_object_keys(payload) t(key)) ||
                          ') VALUES (' ||
                          (SELECT STRING_AGG(quote_literal(payload->>key), ', ') FROM jsonb_object_keys(payload) t(key)) || ')';
        WHEN 'UPDATE' THEN
            IF primary_key IS NULL THEN
                RAISE EXCEPTION 'Primary key payload is required for UPDATE operation';
            END IF;

            sql_query := 'UPDATE ' || table_name || ' SET ' ||
                          (SELECT STRING_AGG(key || ' = ' || quote_literal(payload->>key), ', ') FROM jsonb_object_keys(payload) t(key)) ||
                          ' WHERE ' ||
                          (SELECT STRING_AGG(key || ' = ' || quote_literal(primary_key->>key), ' AND ') FROM jsonb_object_keys(primary_key) t(key));
        WHEN 'DELETE' THEN
            IF primary_key IS NULL THEN
                RAISE EXCEPTION 'Primary key payload is required for DELETE operation';
            END IF;

            sql_query := 'DELETE FROM ' || table_name || ' WHERE ' ||
                          (SELECT STRING_AGG(key || ' = ' || quote_literal(primary_key->>key), ' AND ') FROM jsonb_object_keys(primary_key) t(key));
    END CASE;

    -- Execute the constructed SQL query
    INSERT INTO statements ("sql") values (sql_query);

END;
$$ LANGUAGE plpgsql;
