open Core
open Syntax

module Node = struct
  type t = instruction * int [@@deriving sexp_of, sexp]

  let compare = Stdlib.compare
  let hash = Hashtbl.hash
  let equal = phys_equal
  let index = -1
end

module Edge = struct
  type t = string

  let compare = Stdlib.compare
  let equal = ( = )
  let default = ""
end

let string_of_operand o =
  match o with
  | Int a -> string_of_int a
  | Float a -> Printf.sprintf "%f" a
  | Identifier a -> a

let string_of_instruction i =
  match i with
  | Label a -> a ^ ":"
  | Goto a -> "goto," ^ a
  | Assign (a, b) -> String.concat ~sep:"," [ "assign"; a; string_of_operand b ]
  | Add (a, b, c) ->
      String.concat ~sep:","
        [ "add"; a; string_of_operand b; string_of_operand c ]
  | Sub (a, b, c) ->
      String.concat ~sep:","
        [ "sub"; a; string_of_operand b; string_of_operand c ]
  | Mult (a, b, c) ->
      String.concat ~sep:","
        [ "mult"; a; string_of_operand b; string_of_operand c ]
  | Div (a, b, c) ->
      String.concat ~sep:","
        [ "div"; a; string_of_operand b; string_of_operand c ]
  | And (a, b, c) ->
      String.concat ~sep:","
        [ "and"; a; string_of_operand b; string_of_operand c ]
  | Or (a, b, c) ->
      String.concat ~sep:","
        [ "or"; a; string_of_operand b; string_of_operand c ]
  | Breq (a, b, c) ->
      String.concat ~sep:","
        [ "breq"; a; string_of_operand b; string_of_operand c ]
  | Brneq (a, b, c) ->
      String.concat ~sep:","
        [ "brneq"; a; string_of_operand b; string_of_operand c ]
  | Brlt (a, b, c) ->
      String.concat ~sep:","
        [ "brlt"; a; string_of_operand b; string_of_operand c ]
  | Brgt (a, b, c) ->
      String.concat ~sep:","
        [ "brgt"; a; string_of_operand b; string_of_operand c ]
  | Brgeq (a, b, c) ->
      String.concat ~sep:","
        [ "brgeq"; a; string_of_operand b; string_of_operand c ]
  | Brleq (a, b, c) ->
      String.concat ~sep:","
        [ "brleq"; a; string_of_operand b; string_of_operand c ]
  | Return a -> "return," ^ string_of_operand a
  | Call (a, b) ->
      String.concat ~sep:"," ("call" :: a :: List.map ~f:string_of_operand b)
  | Callr (a, b, c) ->
      String.concat ~sep:","
        ("callr" :: a :: b :: List.map ~f:string_of_operand c)
  | Array_Store (a, b, c) ->
      String.concat ~sep:","
        [ "array_store"; string_of_operand a; b; string_of_operand c ]
  | Array_Load (a, b, c) ->
      String.concat ~sep:"," [ "array_load"; a; b; string_of_operand c ]
  | Array_Assign (a, b, c) ->
      String.concat ~sep:","
        [ "array_assign"; a; string_of_operand b; string_of_operand c ]

module G = Graph.Persistent.Digraph.ConcreteBidirectionalLabeled (Node) (Edge)

let string_of_vertex v =
  let a, b = v in
  string_of_int b ^ ": " ^ string_of_instruction a

module Dot = Graph.Graphviz.Dot (struct
  include G (* use the graph module from above *)

  let edge_attributes (_, e, _) = [ `Label e; `Color 4711 ]
  let default_edge_attributes _ = []
  let get_subgraph _ = None
  let vertex_attributes _ = []
  let vertex_name v = "\"" ^ string_of_vertex v ^ "\""
  let default_vertex_attributes _ = []
  let graph_attributes _ = []
end)

let rec find_label_index instructions label =
  match instructions with
  | [] -> raise (Failure "Not Found")
  | Label a :: t ->
      if String.compare label a = 0 then 0 else 1 + find_label_index t label
  | _ :: t -> 1 + find_label_index t label

let rec init_table instructions nodes i =
  match instructions with
  | [] -> nodes
  | h :: t ->
      let v = G.V.create (h, i) in
      let nodes = Map.add_exn ~key:i ~data:v nodes in
      init_table t nodes (i + 1)

let rec init_nodes instructions g i =
  match instructions with
  | [] -> g
  | hd :: tl ->
      let v = G.V.create (hd, i) in
      let g = G.add_vertex g v in
      init_nodes tl g (i + 1)

let rec add_edges g done_list work_list nodes i =
  match work_list with
  | [] -> g
  | [ h ] -> (
      let v = Map.find_exn nodes i in
      match h with
      | Goto a ->
          let target_node =
            Map.find_exn nodes (find_label_index (done_list @ work_list) a)
          in
          let g = G.add_edge g v target_node in
          g
      | Breq (a, _, _)
      | Brneq (a, _, _)
      | Brgt (a, _, _)
      | Brlt (a, _, _)
      | Brgeq (a, _, _)
      | Brleq (a, _, _) ->
          let t =
            Map.find_exn nodes (find_label_index (done_list @ work_list) a)
          in
          let g = G.add_edge g v t in
          g
      | _ -> g)
  | h :: tl -> (
      let v = Map.find_exn nodes i in
      match h with
      | Return _ -> add_edges g (done_list @ [ h ]) tl nodes (i + 1)
      | Goto a ->
          let target_node =
            Map.find_exn nodes (find_label_index (done_list @ work_list) a)
          in
          let g = G.add_edge g v target_node in
          add_edges g (done_list @ [ h ]) tl nodes (i + 1)
      | Breq (a, _, _)
      | Brneq (a, _, _)
      | Brgt (a, _, _)
      | Brlt (a, _, _)
      | Brgeq (a, _, _)
      | Brleq (a, _, _) ->
          let t =
            Map.find_exn nodes (find_label_index (done_list @ work_list) a)
          in
          let f = Map.find_exn nodes (i + 1) in
          let g = G.add_edge g v t in
          let g = G.add_edge g v f in
          add_edges g (done_list @ [ h ]) tl nodes (i + 1)
      | _ ->
          let target_node = Map.find_exn nodes (i + 1) in
          let g = G.add_edge g v target_node in
          add_edges g (done_list @ [ h ]) tl nodes (i + 1))

module InstrMap = Map.Make (Int)

let make_cfg func =
  let instructions = func.code_body in
  let g = init_nodes instructions G.empty 0 in
  let nodes = init_table instructions InstrMap.empty 0 in
  add_edges g [] instructions nodes 0

(* takes a list of nodes that should be removed from the cfg *)
let sweep_cfg cfg marks =
  let l = G.fold_vertex (fun v l -> v :: l) cfg [] in
  let sorted =
    List.sort
      ~compare:(fun a b ->
        let _, i = a in
        let _, j = b in
        i - j)
      l
  in
  List.filter sorted ~f:(fun a ->
      List.mem marks a ~equal:(fun a b ->
          let _, i = a in
          let _, j = b in
          i = j))

let rec string_of_irtype t =
  match t with
  | IntType -> "int"
  | FloatType -> "float"
  | VoidType -> "void"
  | ArrayType (t, i) -> string_of_irtype t ^ "[" ^ string_of_int i ^ "]"

let rec string_of_params params s =
  match params with
  | [] -> s
  | [ h ] ->
      let i, n = h in
      let t = string_of_irtype i in
      s ^ t ^ " " ^ n
  | h :: tl ->
      let i, n = h in
      let t = string_of_irtype i in
      string_of_params tl s ^ t ^ " " ^ n ^ ", "

let rec string_of_datalist list s =
  match list with
  | [] -> s
  | [ h ] -> (
      match h with
      | VarData a -> s ^ a
      | ArrayData (a, b) -> s ^ a ^ "[" ^ string_of_int b ^ "]")
  | h :: tl ->
      let str =
        match h with
        | VarData a -> a ^ ", "
        | ArrayData (a, b) -> a ^ "[" ^ string_of_int b ^ "], "
      in
      string_of_datalist tl (s ^ str)

let string_of_func func =
  "#start_function\n"
  ^ string_of_irtype func.return_type
  ^ " " ^ func.name ^ "("
  ^ string_of_params func.parameters ""
  ^ "):\n" ^ "int-list: "
  ^ string_of_datalist func.int_list ""
  ^ "\nfloat-list: "
  ^ string_of_datalist func.float_list ""
  ^ "\n"
  ^ String.concat ~sep:"\n"
      (List.map func.code_body ~f:(fun a -> string_of_instruction a))
  ^ "\n#end_function"
