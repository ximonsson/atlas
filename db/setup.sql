-- Addresses
-----------------------------------------------------------------

LOAD fts;

-- create index over ways that represent addresses

CREATE OR REPLACE TABLE wayaddr AS
SELECT
	id, list_aggr(list(v), 'string_agg', ' ') AS tags
FROM (
	SELECT
		waytag.*
	FROM waytag INNER JOIN (
		SELECT DISTINCT id FROM waytag WHERE k ILIKE 'addr:%'
	) AS a ON a.id = waytag.id
)
GROUP BY id;

PRAGMA create_fts_index('wayaddr', 'id', 'tags', overwrite=1);

-- create index over nodes that represent addresses.

CREATE OR REPLACE TABLE nodeaddr AS
SELECT
	id, list_aggr(list(v), 'string_agg', ' ') AS tags
FROM (
	SELECT
		nodetag.*
	FROM nodetag INNER JOIN (
		SELECT DISTINCT id FROM nodetag WHERE k ILIKE 'addr:%'
	) AS a ON a.id = nodetag.id
)
GROUP BY id;

PRAGMA create_fts_index('nodeaddr', 'id', 'tags', overwrite=1);

-- macros for simple address search

CREATE OR REPLACE MACRO addr_search_way(q) AS TABLE
	SELECT
		*
	FROM (
		SELECT
			*, fts_main_wayaddr.match_bm25(id, q) AS score
		FROM wayaddr
	)
	WHERE
		score IS NOT NULL
	ORDER BY score DESC
;

CREATE OR REPLACE MACRO addr_search_node(q) AS TABLE
	SELECT
		*
	FROM (
		SELECT
			*, fts_main_nodeaddr.match_bm25(id, q) AS score
		FROM nodeaddr
	)
	WHERE
		score IS NOT NULL
	ORDER BY score DESC
;

-- Highways
-----------------------------------------------------------------

DROP MACRO IF EXISTS l2dist CASCADE;

CREATE OR REPLACE MACRO l2dist(p_lat, p_lon, q_lat, q_lon) AS
sqrt((p_lat - q_lat) ^ 2 + (p_lon - q_lon) ^ 2);


-- find ways that are highways (streets, highway, etc.)
CREATE OR REPLACE VIEW highway AS
SELECT
	id, v as t
FROM
	waytag
WHERE
	k = 'highway' AND
	regexp_matches(v, '^(motorway|trunk|primary|secondary|tertiary|residential).*$');

-- create table of nodes that are part of streets (highway)
--		creating a table here speeds a lot of things up for later
CREATE OR REPLACE TABLE highway_node AS
SELECT
	highway.id, waynode.node, node.lat, node.lon
FROM highway
LEFT JOIN waynode ON highway.id = waynode.way
LEFT JOIN node ON node.id = waynode.node;

-- calculate distances between nodes in the way and total distance of a way

-- distance between nodes in highways
CREATE OR REPLACE VIEW highway_node_distance AS
SELECT
	*, l2dist(lag(lat) OVER w, lag(lon) OVER w, lat, lon) AS dist
FROM highway_node
WINDOW w AS (PARTITION BY id);

-- highway sum of distance
CREATE OR REPLACE VIEW highway_distance AS
SELECT
	id, sum(dist) AS dist
FROM
	highway_node_distance
GROUP BY id;

-- closest node on a highway from a given node.
CREATE OR REPLACE MACRO dist_to_highway_node(n) AS TABLE
SELECT
	*,
	l2dist(
		(SELECT lat FROM node WHERE id = n),
		(SELECT lon FROM node WHERE id = n),
		lat,
		lon
	) AS d
FROM highway_node
ORDER BY d ASC;

-- Buildings
-----------------------------------------------------------------

-- buildings
CREATE OR REPLACE VIEW building AS
SELECT
	id, v as t
FROM
	waytag
WHERE
	k = 'building';

-- nodes of the buildings
CREATE OR REPLACE VIEW building_node AS
SELECT
	building.id, waynode.node, node.lat, node.lon
FROM building
LEFT JOIN waynode ON building.id = waynode.way
LEFT JOIN node ON waynode.node = node.id;

-- Geometry
--------------------------------------------------------------------

-- are the coordinates within the given bounding box?
CREATE OR REPLACE MACRO within(lat, lon, a1, b1, a2, b2) AS
(lat BETWEEN a1 AND a2) AND (lon BETWEEN b1 AND b2);
