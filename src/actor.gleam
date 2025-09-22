import gleam/erlang/process.{type Pid, self, send}
import gleam/list
import gleam/otp/actor
import gossip
import push_sum
import types

pub fn loop(
  msg: types.ActorMessage,
  // The message to process
  state: #(types.ActorState, Pid),
  // The actor's state tuple: (algorithm_state, supervisor_pid)
) -> actor.Next(#(types.ActorState, Pid), types.ActorMessage) {
  let #(current_actor_state, supervisor) = state

  let #(new_state, actions, converged) = case msg, current_actor_state {
    types.Init(neighbors), actor_state -> {
      let new_state = case actor_state {
        types.GossipActor(s) ->
          gossip.set_neighbors(s, neighbors) |> types.GossipActor
        types.PushSumActor(s) ->
          push_sum.set_neighbors(s, neighbors) |> types.PushSumActor
      }
      #(new_state, [], False)
    }

    types.Start, types.GossipActor(s) -> gossip.handle_start(s, actor.self())
    types.Start, types.PushSumActor(s) -> push_sum.handle_start(s, actor.self())

    types.Work, types.GossipActor(s) -> gossip.handle_work(s, actor.self())
    types.Work, types.PushSumActor(s) -> push_sum.handle_work(s, actor.self())

    types.Node(_, types.Rumor), types.GossipActor(s) -> gossip.handle_rumor(s)
    types.Node(_, types.PushSumValues(rs, rw)), types.PushSumActor(s) ->
      push_sum.handle_push_sum(s, rs, rw)

    // Default case for unexpected messages (e.g., a GossipActor getting a PushSum message)
    _, _ -> #(current_actor_state, [], False)
  }

  case converged {
    // Send to a raw Pid still uses process.send
    True -> send(supervisor, types.Converged)
    False -> Nil
  }

  list.each(actions, fn(action) {
    case action {
      // Use actor.send for type-safe actor-to-actor communication
      types.SendRumor(to) -> actor.send(to, types.Node(self(), types.Rumor))
      types.SendPushSum(to, s, w) ->
        actor.send(to, types.Node(self(), types.PushSumValues(s, w)))
      // Use actor.send_after for delayed messages to self or others
      types.ContinueWork(me) -> {
        actor.send_after(me, types.Work, 1)
        Nil
      }
    }
  })

  actor.continue(#(new_state, supervisor))
}
