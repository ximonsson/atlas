DATABASE=atlas.duckdb
K8S=0  # build for k8s?

server:
	cargo build

database: db/setup.sql db/data.sql
	duckdb $(DATABASE) < db/data.sql
	duckdb $(DATABASE) < db/setup.sql
