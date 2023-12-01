# PostgreSQL replication / Change Data Capture (through Benthos)

Replicates `dbsource` into `dbtarget` via [Benthos][] pipelines, with the help of a PostgreSQL trigger to save all changed data into a changelog table.

Pipelines:
- `benthos-mock` generates mock data into `dbsource`
- `benthos-capture` captures all changes recorded in the `dbsource` changelog table, and sends to a Kafka topic.
- `benthos-target` consumes the Kafka topic and fills `dbtarget`.


## Setup

Run `./init.sh` to create and populate the database.

Then run `docker compose up -d` to start all pipelines.


[Benthos]: https://benthos.dev/
