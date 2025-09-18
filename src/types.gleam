import gleam/dict.{type Dict}

/// Algorithm type enumeration
pub type Algorithm {
  /// Gossip rumor spreading algorithm
  Gossip
  /// Push-Sum distributed averaging algorithm
  PushSum
}

/// Network topology type enumeration
pub type Topology {
  /// Fully connected network - each node is connected to all other nodes
  Full
  /// 3D grid topology - nodes arranged in a 3D cube, each with up to 6 neighbors
  ThreeD
  /// Line topology - nodes arranged in a line, each with up to 2 neighbors
  Line
  /// Imperfect 3D grid - 3D grid with an additional random connection per node
  ImperfectThreeD
}

/// Node state in the Gossip algorithm
pub type GossipState {
  GossipNode(
    /// List of neighbor node IDs
    neighbors: List(Int),
    /// Number of times heard the rumor (stops spreading after 10)
    rumor_count: Int,
    /// Whether still actively spreading rumors
    active: Bool,
  )
}

/// Node state in the Push-Sum algorithm
pub type PushSumState {
  PushSumNode(
    /// List of neighbor node IDs
    neighbors: List(Int),
    /// Sum value (initially node_id + 1)
    s: Float,
    /// Weight value (initially 1.0)
    w: Float,
    /// Number of rounds the s/w ratio remained unchanged
    ratio_unchanged_count: Int,
    /// Previous round's s/w ratio for convergence detection
    last_ratio: Float,
    /// Whether still actively computing
    active: Bool,
  )
}

/// Complete network state containing all nodes
pub type NetworkState {
  /// Gossip network state - dictionary of all Gossip nodes
  GossipNetwork(nodes: Dict(Int, GossipState))
  /// Push-Sum network state - dictionary of all Push-Sum nodes
  PushSumNetwork(nodes: Dict(Int, PushSumState))
}

/// Convert algorithm type to string for display
pub fn algorithm_to_string(algorithm: Algorithm) -> String {
  case algorithm {
    Gossip -> "gossip"
    PushSum -> "push-sum"
  }
}

/// Convert topology type to string for display
pub fn topology_to_string(topology: Topology) -> String {
  case topology {
    Full -> "full"
    ThreeD -> "3D"
    Line -> "line"
    ImperfectThreeD -> "imp3D"
  }
}
