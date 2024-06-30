use duckdb;
use petgraph;
use std::collections::HashMap;

fn open() -> duckdb::Result<duckdb::Connection> {
    let conf = duckdb::Config::default()
        .access_mode(duckdb::AccessMode::ReadOnly)
        .expect("Invalid config");
    duckdb::Connection::open_with_flags("atlas.duckdb", conf)
}

fn graph(c: &duckdb::Connection) -> Result<petgraph::Graph<i64, i64>, duckdb::Error> {
    // fetch number of nodes that are part of highways
    let (n, m): (usize, usize) = c.query_row(
        "SELECT count(DISTINCT node) AS nodes, count(*) AS edges FROM highway_node",
        [],
        |row| Ok((row.get(0)?, row.get(1)?)),
    )?;

    // create graph with capacity
    let mut g = petgraph::Graph::<i64, i64>::with_capacity(n, m);
    let mut nix: HashMap<i64, petgraph::graph::NodeIndex> = HashMap::with_capacity(n);

    // loop over nodes and add them to the graph
    let mut stmt = c.prepare("SELECT DISTINCT node FROM highway_node")?;
    let mut rows = stmt.query([])?;

    while let Ok(Some(r)) = rows.next() {
        let node: i64 = r.get(0)?;
        nix.insert(node, g.add_node(node));
    }

    // create edges
    stmt = c.prepare(
        "SELECT *
        FROM
            (SELECT node, lag(node, -1) OVER (PARTITION BY id) AS nxt FROM highway_node)
        WHERE nxt IS NOT NULL",
    )?;
    rows = stmt.query([])?;

    while let Ok(Some(r)) = rows.next() {
        let (a, b): (i64, i64) = (r.get(0)?, r.get(1)?);
        g.update_edge(nix[&a], nix[&b], 1);
    }

    Ok(g)
}

fn main() {
    println!("Atlas server");

    let con = open().expect("Failed to open database");

    let n: Result<f32, duckdb::Error> =
        con.query_row("SELECT count(*) FROM node", [], |row| row.get(0));
    println!("{} million nodes in database", n.expect("lol") / 1e6);

    let g = graph(&con).expect("fooo");
    println!("{}M nodes in graph", g.node_count() as f32 / 1e6);
    println!("{}M edges in graph", g.edge_count() as f32 / 1e6);
}
