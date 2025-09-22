import gleam/erlang/process.{type Pid, type Subject}

// --- Algorithm & Topology Enums (Unchanged) ---
pub type Algorithm {
  Gossip
  PushSum
}

pub type Topology {
  Full
  ThreeD
  Line
  ImperfectThreeD
}

// --- Actor & Node Messages (Unchanged) ---
pub type NodeMessage {
  Rumor
  PushSumValues(s: Float, w: Float)
}

pub type ActorMessage {
  Init(neighbors: List(Subject(ActorMessage)))
  Start
  Node(from: Pid, msg: NodeMessage)
  Work
}

// --- Supervisor Messages ---
pub type SupervisorMessage {
  Converged
}

// --- State Definitions (Unchanged) ---
pub type GossipState {
  GossipState(rumor_count: Int, neighbors: List(Subject(ActorMessage)))
}

pub type PushSumState {
  PushSumState(
    s: Float,
    w: Float,
    last_ratio: Float,
    ratio_unchanged_count: Int,
    neighbors: List(Subject(ActorMessage)),
  )
}

pub type ActorState {
  GossipActor(GossipState)
  PushSumActor(PushSumState)
}

// --- NEW: Unified Action Type ---
// This defines all possible actions an actor can take, regardless of algorithm.
pub type Action {
  SendRumor(to: Subject(ActorMessage))
  SendPushSum(to: Subject(ActorMessage), s: Float, w: Float)
  ContinueWork(me: Subject(ActorMessage))
}