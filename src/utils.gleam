import gleam/int
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

  // use num_nodes <- result.try(case int.parse(num_nodes_str) {
  //   Ok(n) if n > 0 -> Ok(n)
  //   Ok(n) -> {
  //     // 输出解析成功但值无效的情况
  //     Error("Invalid number of nodes: " <> int.to_string(n) <> " (must be > 0)")
  //   }
  //   Error(_) -> Error("Invalid number of nodes: '" <> num_nodes_str <> "' is not a valid integer")
  // })

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

/// Convert Topology type to string for display
pub fn topology_to_string(topology: Topology) -> String {
  case topology {
    Full -> "full"
    ThreeD -> "3D"
    Line -> "line"
    ImperfectThreeD -> "imp3D"
  }
}

/// Convert Algorithm type to string for display
pub fn algorithm_to_string(algorithm: Algorithm) -> String {
  case algorithm {
    Gossip -> "gossip"
    PushSum -> "push-sum"
  }
}
