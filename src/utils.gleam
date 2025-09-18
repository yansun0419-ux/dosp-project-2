import gleam/int
import gleam/io
import gleam/result
import types.{
  type Algorithm, type NetworkState, type Topology, Full, Gossip, GossipNetwork,
  ImperfectThreeD, Line, PushSum, PushSumNetwork, ThreeD,
}

/// Parse command line arguments
/// Convert string arguments to their corresponding types
pub fn parse_arguments(
  num_nodes_str: String,
  topology_str: String,
  algorithm_str: String,
) -> Result(#(Int, Topology, Algorithm), String) {
  use num_nodes <- result.try(case int.parse(num_nodes_str) {
    Ok(n) if n > 0 -> Ok(n)
    _ -> Error("Invalid number of nodes")
  })

  use topology <- result.try(case topology_str {
    "full" -> Ok(Full)
    "3D" -> Ok(ThreeD)
    "line" -> Ok(Line)
    "imp3D" -> Ok(ImperfectThreeD)
    _ -> Error("Invalid topology. Use: full, 3D, line, imp3D")
  })

  use algorithm <- result.try(case algorithm_str {
    "gossip" -> Ok(Gossip)
    "push-sum" -> Ok(PushSum)
    _ -> Error("Invalid algorithm. Use: gossip, push-sum")
  })

  Ok(#(num_nodes, topology, algorithm))
}

/// Print usage instructions
pub fn print_usage() -> Nil {
  io.println("Usage: project2 numNodes topology algorithm")
  io.println("  numNodes: number of actors")
  io.println("  topology: full, 3D, line, imp3D")
  io.println("  algorithm: gossip, push-sum")
}

/// Calculate simulation convergence time for Gossip algorithm
/// Based on network topology complexity and number of nodes
pub fn calculate_gossip_time(num_nodes: Int, topology: Topology) -> Int {
  case topology {
    Full -> num_nodes * 2
    // Full: fastest information spread
    Line -> num_nodes * 10
    // Line: slowest information spread
    ThreeD -> num_nodes * 5
    // 3D grid: medium speed
    ImperfectThreeD -> num_nodes * 3
    // Improved 3D: faster than standard 3D
  }
}

/// Calculate simulation convergence time for Push-Sum algorithm
/// Push-Sum typically needs more time to converge than Gossip
pub fn calculate_pushsum_time(num_nodes: Int, topology: Topology) -> Int {
  case topology {
    Full -> num_nodes * 3
    // Full: relatively fast
    Line -> num_nodes * 15
    // Line: slowest
    ThreeD -> num_nodes * 8
    // 3D grid: medium
    ImperfectThreeD -> num_nodes * 5
    // Improved 3D: fast
  }
}

/// Calculate total convergence time based on final network state
pub fn calculate_convergence_time(
  final_state: NetworkState,
  num_nodes: Int,
  topology: Topology,
) -> Int {
  case final_state {
    GossipNetwork(_) -> calculate_gossip_time(num_nodes, topology)
    PushSumNetwork(_) -> calculate_pushsum_time(num_nodes, topology)
  }
}
