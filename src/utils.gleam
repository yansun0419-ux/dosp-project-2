import gleam/int
import gleam/result
import types.{
  type Algorithm, type Topology, Full, Gossip,
  ImperfectThreeD, Line, PushSum, ThreeD,
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
