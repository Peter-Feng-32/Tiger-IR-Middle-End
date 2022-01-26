
(* The type of tokens. *)

type token = 
  | VOID_TYPE
  | SUB
  | START_FUNCTION
  | RIGHT_PARENTHESIS
  | RIGHT_BRACKET
  | RETURN
  | OR
  | MULT
  | LEFT_PARENTHESIS
  | LEFT_BRACKET
  | INT_TYPE
  | INT_LIST
  | INT of (int)
  | ID of (string)
  | GOTO
  | FLOAT_TYPE
  | FLOAT_LIST
  | FLOAT of (float)
  | EOL
  | EOF
  | END_FUNCTION
  | DOT
  | DIV
  | COMMA
  | COLON
  | CALLR
  | CALL
  | BRNEQ
  | BRLT
  | BRLEQ
  | BRGT
  | BRGEQ
  | BREQ
  | ASSIGN
  | ARRAY_STORE
  | ARRAY_LOAD
  | AND
  | ADD

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val prog: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (func list)
