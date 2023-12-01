-- CREATE DATABASE dbsource;

CREATE TYPE table_change_type AS ENUM ('UPDATE', 'INSERT', 'DELETE');

CREATE TABLE src_changes (
    id bigserial primary key,

    table_name varchar(255) not null,
    operation table_change_type not null,
    old_data jsonb,
    new_data jsonb,
    transaction_time timestamptz not null,
    transaction_id bigint,

    publish_time timestamptz default null
);

CREATE TABLE IF NOT EXISTS src_example (id bigserial primary key, created_at timestamptz not null);

CREATE OR REPLACE FUNCTION changelog_trigger() returns trigger as $$
declare
  action text;
  table_name text;
  transaction_id bigint;
  timestamp timestamptz;
  old_data jsonb;
  new_data jsonb;
begin
  action := upper(TG_OP::text);
  table_name := TG_TABLE_NAME::text;
  transaction_id := txid_current();
  timestamp := current_timestamp;

  if TG_OP = 'DELETE' then
    old_data := to_jsonb(OLD.*);
  elseif TG_OP = 'INSERT' then
    new_data := to_jsonb(NEW.*);
  elseif TG_OP = 'UPDATE' then
    old_data := to_jsonb(OLD.*);
    new_data := to_jsonb(NEW.*);
  end if;

  insert into src_changes (operation, table_name, transaction_id, transaction_time, old_data, new_data)
  values (
    action::table_change_type,
    TG_TABLE_SCHEMA::text || '.' || TG_TABLE_NAME::text,
    transaction_id,
    timestamp,
    old_data,
    new_data
  );

  return null;
end;
$$ language plpgsql;

create trigger tg_example after insert or update or delete on src_example
for each row execute function changelog_trigger();
