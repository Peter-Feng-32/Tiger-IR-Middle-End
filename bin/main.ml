open Core
(** Main entry point for our application. *)

open Lexer
open Lexing
open Syntax
open Cfg
open Deadcode

let print_cfg cfg name =
  let file = Caml.open_out (name ^ ".dot") in
  Dot.output_graph file cfg

let process_func func =
  let cfg = Cfg.make_cfg func in
  print_cfg cfg "og";
  let marks = Deadcode.runMarkAlgorithm cfg in
  let opt =
    List.map
      ~f:(fun a ->
        let i, _ = a in
        i)
      (Cfg.sweep_cfg cfg marks)
  in
  let new_func =
    {
      name = func.name;
      return_type = func.return_type;
      parameters = func.parameters;
      int_list = func.int_list;
      float_list = func.float_list;
      code_body = opt;
    }
  in
  let new_cfg = Cfg.make_cfg new_func in
  print_cfg new_cfg "new";
  Cfg.string_of_func new_func

let print_position outx lexbuf =
  let pos = lexbuf.lex_curr_p in
  fprintf outx "%s:%d:%d" pos.pos_fname pos.pos_lnum
    (pos.pos_cnum - pos.pos_bol + 1)

let parse_with_error lexbuf =
  try Parser.prog Lexer.read lexbuf with
  | SyntaxError msg ->
      fprintf stderr "%a: %s\n" print_position lexbuf msg;
      []
  | Parser.Error ->
      fprintf stderr "%a: syntax error\n" print_position lexbuf;
      exit (-1)

(* Todo: Implement parsing + printing multiple functions *)

let parse_and_print funcs filename =
  let str =
    List.fold funcs ~init:"" ~f:(fun s func -> s ^ "\n" ^ process_func func)
  in
  let oc = Out_channel.create filename in
  Printf.fprintf oc "%s" str;
  Out_channel.close oc;
  ()

let loop filename () =
  let inx = In_channel.create filename in
  let lexbuf = Lexing.from_channel inx in
  lexbuf.lex_curr_p <- { lexbuf.lex_curr_p with pos_fname = filename };
  parse_and_print (parse_with_error lexbuf) "optimized.ir";
  printf "Test %s\n" "Done";
  In_channel.close inx

let () =
  Command.basic_spec ~summary:"Parse and display JSON"
    Command.Spec.(empty +> anon ("filename" %: string))
    loop
  |> Command.run
