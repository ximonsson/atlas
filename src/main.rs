use duckdb::arrow::record_batch::RecordBatch;
use duckdb::arrow::util::pretty::print_batches;
use duckdb::{params, Connection, Result};

use petgraph::algo::{dijkstra, min_spanning_tree};
use petgraph::data::FromElements;
use petgraph::dot::{Config, Dot};
use petgraph::graph::{NodeIndex, UnGraph};

fn main() {
    println!("Hello, world!");
}
