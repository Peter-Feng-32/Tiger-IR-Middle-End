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
(* To get this hashtable, first have a list of critical operations*)
(* Iterate through the graph and mark all critical ops *)
(* Keep a worklist *)
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
    | Assign(_)
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
    | Assign(dest, _)
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


let initializeDataFlowTable cfg =
  let dataFlowTable = Hashtbl.create(module Node) in
  let () = G.iter_vertex (fun v -> 
    Hashtbl.add_exn dataFlowTable ~key: v ~data: {
      genSet = Hashtbl.create(module Node);
      killSet = Hashtbl.create(module Node);
      inSet = Hashtbl.create(module Node);
      outSet = Hashtbl.create(module Node)
    }
  ) cfg in 
  dataFlowTable
  
let fillGenAndKillSets cfg dataflowTable destToDefsTable= 
  G.iter_vertex (
    fun v -> 
    let (instr, num) = v in 
    let dataflows = Hashtbl.find dataflowTable v in
      match dataflows with 
        | Some x -> 
          if (isDef instr) then
            (*Fill Gen Set*)
            let () = Hashtbl.add_exn x.genSet ~key: v ~data: true in (* Data doesn't matter because we are using these as sets *)
            let () = printf " Fill Gen Set\n " in
            (* Fill Kill Set*)
            (* Get current instruction dest *)
            (* Get the set of defs for current instruction *)
            (* Kill Set = Set of Defs for current instruction - current node *)
            let currDest = getDestOfDef instr in
            (
              match currDest with 
              | Some currDest -> 
                let currDestDefs = Hashtbl.find_exn destToDefsTable currDest in 
                let killSetCreated = Hashtbl.create (module Node) in
                let () = List.iter currDestDefs ~f: (fun node -> Hashtbl.add_exn killSetCreated ~key: node ~data: true) in
                let () = Hashtbl.remove killSetCreated v in
                let () = x.killSet <- killSetCreated in
                ()
              | None -> ()
            )
        | None -> ()
  )
 cfg

 (* Map each node to a list of nodes that are its predecessors *)
let mapPredecessors cfg = 
  let predecessorMap = Hashtbl.create(module Node) in
  let () = G.iter_edges 
  (fun pred succ -> 
    let existingList = Hashtbl.find predecessorMap succ in 
      match existingList with 
      | Some l ->  Hashtbl.set predecessorMap ~key: succ ~data: (List.append l [pred])
      | None -> Hashtbl.add_exn predecessorMap ~key: succ ~data: [pred]
  ) cfg in predecessorMap

  (* Update In and Out Sets until there are no changes left *)
  (* *)

let equalDataflowSets left right =
  Hashtbl.equal left right
let print_dataflow cfg dataflowSetsTable node= 
  let copied_sets = Hashtbl.find_exn dataflowSetsTable node in
  let ins, num = node in 
  let () = printf "\nNode %d\n" num in
    let () = printf "Iterating over gen\n" in
    let () = Hashtbl.iter_keys copied_sets.genSet ~f: (fun n -> let ins, i = n in printf "Gen %d\n" i) in
    let () = printf "Done iterating over gen\n" in 

    let () = printf "Iterating over kill\n" in
    let () = Hashtbl.iter_keys copied_sets.killSet ~f: (fun n -> let ins, i = n in printf "Kill %d\n" i) in
    let () = printf "Done iterating over kill\n" in 
    let () = printf "Iterating over in\n" in
    let () = Hashtbl.iter_keys copied_sets.inSet ~f: (fun n -> let ins, i = n in printf "In %d\n" i) in
    let () = printf "Done iterating over in\n" in 

    let () = printf "Iterating over out\n" in
    let () = Hashtbl.iter_keys copied_sets.outSet ~f: (fun n -> let ins, i = n in printf "Out %d\n" i) in
    let () = printf "Done iterating over out\n\n" in ()


    (*
    To run the dataflow analysis,
    1) Make a copy of the hash table consisting of each vertice's in/out/gen/kill sets
    2) traverse over all vertices in the graph and set the in_sets in the copied hash table to the union of their predecessors' outs in the original
    3) traverse over all vertices in the graph and set the out_sets in the copied hash table to be gen u (in - kill) (all from the copied table)
      Look into filter keys for time efficiency purposes
    4) Compare the original and copied hashtables.  if they are the same, return one of them.  Otherwise recurse
     *)
let rec runDataFlowAnalysis cfg dataFlowSetsTable = 
  let predMap = mapPredecessors cfg in 
  let copiedDataFlowSetsTable = Hashtbl.copy dataFlowSetsTable in
  let fixedpt = ref true in
  let () = printf "RUNNING DATAFLOW ANALYSIS \n" in

  let () = G.iter_vertex 
  (fun v -> 
    let copied_sets = {
      genSet = Hashtbl.copy (Hashtbl.find_exn dataFlowSetsTable v).genSet;
      killSet = Hashtbl.copy (Hashtbl.find_exn dataFlowSetsTable v).killSet;
      inSet = Hashtbl.copy (Hashtbl.find_exn dataFlowSetsTable v).inSet;
      outSet= Hashtbl.copy (Hashtbl.find_exn dataFlowSetsTable v).outSet 
    } in

    let () = Hashtbl.set copiedDataFlowSetsTable ~key: v ~data: copied_sets in
    (* Get out set of each predecessor node from original and put those nodes into the copied_in_set*)
    let copied_in_set = Hashtbl.create(module Node) in 
    let predList =  
    (match Hashtbl.find predMap v with 
      | Some x -> x
      | None -> []
    ) in
    (*let () = printf "Iterating through predList\n" in *) (* Testing purposes *)

    (* let () = List.iter predList ~f: (fun n -> let ins, i = n in printf "Pred %d\n" i) in *)(* Testing purposes *)

    let () = List.iter (predList) ~f: (fun pred_node -> (
      let pred_out_set_orig  = (Hashtbl.find_exn dataFlowSetsTable pred_node).outSet in
      Hashtbl.iter_keys pred_out_set_orig ~f: (fun v -> 
        (*let () = let ins, num = v in printf "Adding from pred to inset %d\n" num in *) (* Testing purposes *)
          let _ = Hashtbl.add copied_in_set ~key: v ~data: true in ()
        )
    )) in
    (*let () = printf "Done iterating through predList\n" in *)(* Testing purposes *)

    let () = copied_sets.inSet <- copied_in_set in 
    (* Set copied out set to be gen u copied (in - kill) *)
    let copied_out_set = Hashtbl.copy (copied_sets.genSet) in
    let copied_in_minus_kill = Hashtbl.merge copied_in_set copied_sets.killSet ~f: (
    (* In - Kill function *)
    fun ~key:_ -> function
        | `Left x -> Some x
        | `Right _ -> None 
        | `Both _ -> None
    ) in
    let copied_out_set = Hashtbl.merge copied_out_set copied_in_minus_kill ~f: (
    fun ~key:_ -> function
    (* Union function *)
    | `Left x -> Some x
    | `Right x -> Some x 
    | `Both (x, _) -> Some x
    ) in
    let () = copied_sets.outSet <- copied_out_set in

    let ins, num = v in 
    let _ = if num == 12 then 
      (print_dataflow cfg copiedDataFlowSetsTable v)
    in
    (* Compare original and copied in and out sets *)
    (* If they are different, recurse *)
    let fixed = Hashtbl.equal (fun b1 b2 -> true) copied_in_set (Hashtbl.find_exn dataFlowSetsTable v).inSet && 
    Hashtbl.equal (fun b1 b2 -> true) copied_out_set (Hashtbl.find_exn dataFlowSetsTable v).outSet in
    if (fixed) then 
      ()
    else
      fixedpt := false
      
  ) cfg 
  in
  if (!fixedpt) 
    then 
    let () = printf "FINALLY DONE WITH DATAFLOW ANALYSIS \n" in
    copiedDataFlowSetsTable 
  else 
    let () = printf "DONE WITH DATAFLOW ANALYSIS ITERATION \n" in

    runDataFlowAnalysis cfg copiedDataFlowSetsTable


let mapDestsToDefs cfg destToDefTable = 
  G.iter_vertex ( fun v -> 
    let (instr, num) = v in 
    let dest = getDestOfDef instr in 
      match dest with 
      | Some cDest -> (* x is the destination of our def *)
        let currDefList = Hashtbl.find destToDefTable cDest in  (* This is the current set of defs matched to our destination.  We want to add x to it*)
          (match currDefList with 
            | Some cDefList -> (
              Hashtbl.set destToDefTable ~key: cDest ~data: (v :: cDefList) (* Add the current def'ing node to our dest list.  The data doesnt matter *)
            ) 
            | None -> (
              Hashtbl.add_exn destToDefTable ~key: cDest ~data: [v]
            )
          )
      | None -> ()
    ) cfg

(* To Run Deadcode Elimination 
 1) Mark all critical instruction nodes and add them to worklist 
 2) Iterate through worklist 
 3) For every node in the worklist, get all nodes that write to its operands(if they are variables(strings))
  To get those nodes, look at all reaching definitions nodes and find those that write to same destination.
 4) If those nodes are not marked, mark and add those nodes to worklist
 *)

let getOperandList(ins) = 
  match ins with 
  | Breq(s, op1, op2)
  | Brneq(s, op1, op2)
  | Brgeq(s, op1, op2)
  | Brleq(s, op1, op2)
  | Brgt(s, op1, op2)
  | Brlt(s, op1, op2)
  | Add(s, op1, op2)
  | Sub(s, op1, op2)
  | Mult(s, op1, op2)
  | Div(s, op1, op2)
  | And(s, op1, op2)
  | Or(s, op1, op2)
  -> [op1; op2]
  | Assign(s, op1)
  -> [op1]
  | Call(s1, oplist)
  -> oplist
  | Callr(s1, s2, oplist)
  -> oplist
  | Array_Store(op1, s, op2)
  -> [op1; op2]
  | Array_Load(x, arrayname, opindex)
  -> [opindex]
  | Array_Assign(x, op1, op2)
  -> [op1; op2]
  | _ -> []


let mark cfg markedTable dataflowSetsTable destToDefsTable =
  (* Mark all critical instructions and add them to worklist *)
  let worklistR = ref [] in 
  let () = G.iter_vertex 
    ( fun v -> 
      let ins, _ = v in
      if isCritical ins then
        match Hashtbl.find markedTable v with 
        | Some x -> () (* Vertex was already marked *)
        | None -> 
          let () = Hashtbl.add_exn markedTable ~key: v ~data: true in
          worklistR := List.append !worklistR [v]
    ) cfg in

  let rec mark_iterate cfg markedTable dataflowSetsTable destToDefsTable worklist =
    (match worklist with 
    | [] -> () (*Empty worklist: finished *)
    | a :: rest -> 
      let ins, num = a in 
      (* Get item from worklist, mark new items and add them to worklist and call mark_iterate recursively *)
      let list_of_operands = getOperandList ins in
      let string_operands = List.fold ~init: [] ~f: (
      fun acc op -> match op with
        | Identifier o -> 
          o :: acc
        | _ -> acc
      ) list_of_operands in

      (* Get new marked nodes by marking all unmarked nodes that write to our list of operands and are in the in_set of the dataflow sets of the current node *)
      let new_nodes_to_mark = List.fold ~init: [] ~f: ( (* For each operation on a string(variable) *)
        fun acc strop -> 
          (* Get a list of all nodes that will write to the variable in question (look up the variable in destToDefsTable) *)
          let allDefingNodesList = Hashtbl.find destToDefsTable strop in (*Will be Some(list) or None*)
          (* Iterate through all Defing Nodes and check if they are in the in_set of our current vertex and unmarked *)
          let in_set_curr = (Hashtbl.find_exn dataflowSetsTable a).inSet in
          let () = printf "Curr Node: %d\n" num in
          let () = printf "Curr Variable: %s\n" strop in 
          match allDefingNodesList with 
            | Some lst -> 
              let () = List.iter lst ~f: (fun node -> 
                let ins, num = node in printf "Def: %d\n" num) in 
              (* Check if the nodes are in the in_set of our current vertex a *)
              let nodes_to_mark = List.fold ~init: [] ~f: (
                fun acc n -> 


                  match (Hashtbl.find in_set_curr n) with
                  | Some b -> 
                    let _ = printf "Found a match in inset \n" in 
                    (n :: acc)
                  | None -> 

                    let _ = printf "Did not find a match in inset \n"  in  
                    acc
                ) lst in 
              (* Check if the nodes are not yet marked *)
              let nodes_to_mark_2 = List.fold ~init: [] ~f: (
                fun acc n -> 
                  match (Hashtbl.find markedTable n) with
                  | Some b -> acc
                  | None -> (n :: acc)
                ) nodes_to_mark in 
              List.append nodes_to_mark_2 acc
            | None ->
              acc
      ) string_operands in
      (* Mark all new nodes *)
      let () = List.iter new_nodes_to_mark ~f: (fun node -> 
        Hashtbl.set markedTable ~key: node ~data: true
      ) in
      (* Add all new nodes to worklist *)

      mark_iterate cfg markedTable dataflowSetsTable destToDefsTable (List.append rest new_nodes_to_mark)
    ) 
    in mark_iterate cfg markedTable dataflowSetsTable destToDefsTable !worklistR



  (* runMarkAlgorithm Should return a list of marked nodes *)
let runMarkAlgorithm cfg = 
  let markedTable = Hashtbl.create(module Node) in 
  let destToDefsTable = Hashtbl.create(module String) in (* Table that maps each variable to all nodes which write to it*)
  let () = mapDestsToDefs cfg destToDefsTable in
  let dataflowSetsTable = initializeDataFlowTable cfg in
  let () = fillGenAndKillSets cfg dataflowSetsTable destToDefsTable in
  let dataflowSetsTable = runDataFlowAnalysis cfg dataflowSetsTable in 

  let () = mark cfg markedTable dataflowSetsTable destToDefsTable in 
  Hashtbl.fold ~init: [] ~f: (fun ~key: k ~data: b acc -> 
    k :: acc
  ) markedTable

  let printDataflowSet = ();