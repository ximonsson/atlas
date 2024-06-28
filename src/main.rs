use duckdb;
use petgraph;

fn open() -> duckdb::Result<duckdb::Connection> {
    let conf = duckdb::Config::default()
        .access_mode(duckdb::AccessMode::ReadOnly)
        .expect("Invalid config");
    duckdb::Connection::open_with_flags("atlas.duckdb", conf)
}

fn graph(c: &duckdb::Connection) -> Result<petgraph::Graph<i64, i64>, duckdb::Error> {
    // fetch number of nodes that are part of highways
    let n: usize = c.query_row("SELECT count(*) FROM node", [], |row| row.get(0))?;

    // create graph with capacity
    let mut g = petgraph::Graph::<i64, i64>::with_capacity(n.into(), n.into());

    // loop over nodes and add them to the graph
    let mut stmt = c.prepare("SELECT node FROM highway_node")?;
    let mut rows = stmt.query([])?;

    while let Ok(Some(r)) = rows.next() {
        g.add_node(r.get(0)?);
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
}
