open Core
open Syntax

include Cfg

(* Structure *)
(* First we map each variable to a set of its defs *)
(* We must have a hashmap mapping each vertex to its Gen, Kill, In, and Out Sets. *)
(* Then Gen Set is made by checking the instruction of the current vertex and if it defines something, adding to the empty set (line number, what is being defined)*)
(* Then kill set is made by checking all defs for defs that write to the same destination*)
(* Then in and out are computed using gen and kill*)
(* Note that each vertex must know its predecessors, or check ocamlgraph and iterate through all edges with iter_edges *)

type 'a dataflowSets = {
  mutable genSet: 'a;
  mutable killSet: 'a;
  mutable inSet: 'a;
  mutable outSet: 'a;
}

let fold_map_defs node acc = 
  let (ins, num) = node in
    match ins with 
    | Add(dest, _, _) 
    | Sub(dest, _, _) 
    | Mult(dest, _, _) 
    | Div(dest, _, _)
    | And(dest, _, _)
    | Or(dest, _, _)
    | Callr(dest, _, _)
    | Array_Store (_, dest, _)
    | Array_Load (_, dest, _)
    | Array_Assign (dest, _, _) ->
      begin
        let emptySet = Set.empty(module Int) in
      match Map.find acc dest with
        | Some x -> Map.set acc dest (Set.add x num)
        | None -> Map.add_exn acc dest (Set.add emptySet num)
      end
    | _ -> acc

  
  (* Maps every variable to a set of defs which write to them*)
let map_defs cfg = 
  let emp = Map.empty(module String) in
  G.fold_vertex fold_map_defs cfg emp

  (* Map vertex number to dataflow set*)
let map_dataflow_sets cfg = 
  let emptyMap = Map.empty(module Int) in 
  G.fold_vertex (fun v acc -> 
  let (ins, num) = v in 
  let dfSets = {
    genSet = Set.empty(module Int);
    killSet = Set.empty(module Int);
    inSet = Set.empty(module Int);
    outSet = Set.empty(module Int);
  } in 
  Map.set acc num dfSets ) cfg emptyMap

let fillGenSets cfg defMap dataflowSetsMap = 
  G.iter_vertex (fun v -> 
    let(ins, num) = v in
      match ins with 
      | Add(dest, _, _) 
      | Sub(dest, _, _) 
      | Mult(dest, _, _) 
      | Div(dest, _, _)
      | And(dest, _, _)
      | Or(dest, _, _)
      | Callr(dest, _, _)
      | Array_Store (_, dest, _)
      | Array_Load (_, dest, _)
      | Array_Assign (dest, _, _) ->
        begin 
      let curr = Map.find dataflowSetsMap num in
        match curr with 
        | Some sets -> 
          let newGenSet = Set.add sets.genSet num in
            sets.genSet <- newGenSet
        | None -> ()
        end
      | _ -> ()
    ) cfg 

let runDataFlows cfg = 
  let defMap = map_defs cfg in
  let dataflowSetsMap = map_dataflow_sets cfg in
  let fill = fillGenSets cfg defMap dataflowSetsMap in 
  

