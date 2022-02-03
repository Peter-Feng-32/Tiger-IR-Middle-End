open Core
(** Main entry point for our application. *)

open Lexer
open Lexing
open Syntax
open Cfg



let print_cfg cfg =
  let file = Caml.open_out "cfg.dot" in
  Dot.output_graph file cfg

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

let rec parse_and_print lexbuf =
  match parse_with_error lexbuf with
  | [] -> ()
  | [ a ] ->
      printf "test1%s\n" a.name;

      let cfg = Cfg.make_cfg a in
      print_cfg cfg
  | a :: _ ->
      printf "test2%s\n" a.name;
      parse_and_print lexbuf



let loop filename () =
  let inx = In_channel.create filename in
  let lexbuf = Lexing.from_channel inx in
  lexbuf.lex_curr_p <- { lexbuf.lex_curr_p with pos_fname = filename };
  parse_and_print lexbuf;
  In_channel.close inx

let () =
  Command.basic_spec ~summary:"Parse and display JSON"
    Command.Spec.(empty +> anon ("filename" %: string))
    loop
  |> Command.run
