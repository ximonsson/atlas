-- nodes
CREATE OR REPLACE TABLE node AS
	SELECT * FROM read_parquet(getenv('OSM_DATA_DIR') || '/nodes.parquet');
CREATE OR REPLACE TABLE nodetag AS
	SELECT * FROM read_parquet(getenv('OSM_DATA_DIR') || '/node-tags.parquet');

-- ways
CREATE OR REPLACE TABLE way AS
	SELECT * FROM read_parquet(getenv('OSM_DATA_DIR') || '/ways.parquet');
CREATE OR REPLACE TABLE waytag AS
	SELECT * FROM read_parquet(getenv('OSM_DATA_DIR') || '/way-tags.parquet');
CREATE OR REPLACE TABLE waynode AS
	SELECT * FROM read_parquet(getenv('OSM_DATA_DIR') || '/way-nodes.parquet');

-- relations
CREATE OR REPLACE TABLE rel AS
	SELECT * FROM read_parquet(getenv('OSM_DATA_DIR') || '/relations.parquet');
CREATE OR REPLACE TABLE reltag AS
	SELECT * FROM read_parquet(getenv('OSM_DATA_DIR') || '/relation-tags.parquet');
CREATE OR REPLACE TABLE relmem AS
	SELECT * FROM read_parquet(getenv('OSM_DATA_DIR') || '/relation-members.parquet');
