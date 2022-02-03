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



(* Goal: Return a table of marked numbers - everything else is deadcode*)
(* Hashtbl of vertices -> Marked or Not*)
(* To get this hashtable, first have a hashtable of critical operations*)
(* Iterate through the graph and mark all critical ops *)
(* Keep a worklist of critical ops *)
(* Iterate through the worklist and remove elements + mark ops that write to the critical ops and add them to worklist based on reaching definitions*)
(* For reaching definitions, keep a hashtable of 4 sets: gen, kill, in, out *)
(* Recursively update these sets until no changes*)
(* To recursively update these sets, make each set a hashtable where we ignore the value *)


(* Map each variable (String) to a set of nodes that define it *)

let isCritical ins = 
  match ins with 
    | Label(_)
    | Goto(_)
    | Breq(_)
    | Brneq(_)
    | Brleq(_)
    | Brgeq(_)
    | Brgt(_)
    | Brlt(_)
    | Call(_)
    | Callr(_)
    | Array_Store(_)
    | Array_Assign(_)
    | Return(_) -> true
    | _ -> false

let isDef ins = 
  match ins with 
    | Add(_) 
    | Sub(_)
    | Mult(_)
    | Div(_) 
    | And(_)
    | Or(_)
    | Callr(_)
    | Array_Load(_)
    | Array_Assign(_) ->
      true
    | _ -> false

let getDestOfDef ins = 
  match ins with 
    | Add(dest, _, _)
    | Sub(dest, _, _)
    | Mult(dest, _, _)
    | Div(dest, _, _)
    | Or(dest, _, _)
    | And(dest, _, _)
    | Callr(dest, _, _)
    | Array_Load(dest, _, _)
    | Array_Assign(dest, _, _)
    -> Some(dest)
    | _ -> None


let initializeDataFlowTable cfg dataFlowTable =
  G.iter_vertex (fun v -> 
    Hashtbl.add_exn dataFlowTable ~key: v ~data: {
      genSet = Hashtbl.create(module Node);
      killSet = Hashtbl.create(module Node);
      inSet = Hashtbl.create(module Node);
      outSet = Hashtbl.create(module Node)
    }
  ) cfg 
  
let fillGenAndKillSets cfg dataflowTable destToDefsTable= 
  G.iter_vertex (
    fun v -> 
    let (instr, num) = v in 
    let dataflows = Hashtbl.find dataflowTable v in
      match dataflows with 
        | Some x -> 
          if (isDef instr) then
            let () = Hashtbl.add_exn x.genSet ~key: v ~data: true in (* Data doesn't matter because we are using these as sets *)
            (* Fill Kill Set*)
            (* Get current instruction dest *)
            (* Get the set of defs for current instruction *)
            (* Kill Set = Set of Defs for current instruction - current node *)
            let currDest = getDestOfDef instr in
            (
              match currDest with 
              | Some currDest -> 
                let currDestDefs = Hashtbl.find_exn destToDefsTable currDest in 
                let killSetCreated = Hashtbl.copy currDestDefs in
                let () = Hashtbl.remove killSetCreated v in
                let () = x.killSet <- killSetCreated in
                ()
              | None -> ()
            )
        | None -> ()
  )
 cfg

let mapDestsToDefs cfg destToDefTable = 
  G.iter_vertex ( fun v -> 
    let (instr, num) = v in 
    let dest = getDestOfDef instr in 
      match dest with 
      | Some cDest -> (* x is the destination of our def *)
        let currDefSet = Hashtbl.find destToDefTable cDest in  (* This is the current set of defs matched to our destination.  We want to add x to it*)
          (match currDefSet with 
            | Some cDefSet -> (
              Hashtbl.add_exn cDefSet ~key: v ~data: true (* Add the current def'ing node to our dest set.  The data doesnt matter *)
            ) 
            | None -> (
              let newDefSet = Hashtbl.create(module Node) in
              let () = Hashtbl.add_exn newDefSet ~key: v ~data: true in
              Hashtbl.add_exn destToDefTable ~key: cDest ~data: newDefSet
            )
          )
      | None -> ()
    ) cfg


let runDataFlows cfg = 
  let markedTable = Hashtbl.create(module Node) in
  let dataflowSetsTable = Hashtbl.create(module Node) in
  let destToDefsTable = Hashtbl.create(module String) in (* Table that maps each variable to all nodes which write to it*)
  let () = mapDestsToDefs cfg destToDefsTable in

  0

