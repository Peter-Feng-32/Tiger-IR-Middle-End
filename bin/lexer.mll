{
open Lexing
open Parser

exception SyntaxError of string

let next_line lexbuf =
  let pos = lexbuf.lex_curr_p in
  lexbuf.lex_curr_p <-
    { pos with pos_bol = pos.pos_cnum;
               pos_lnum = pos.pos_lnum + 1
    }
}

let int = '-'? ['0'-'9'] ['0'-'9']*
let digit = ['0'-'9']
let frac = '.' digit*

let float = '-'? digit* frac?

let white = [' ' '\t']+
let newline = '\r' | '\n' | "\r\n"
let id = ['a'-'z' 'A'-'Z' '_'] ['a'-'z' 'A'-'Z' '0'-'9' '_']*

rule read = 
parse
| white {read lexbuf }
| newline { next_line lexbuf; EOL; }
| int { INT (int_of_string (Lexing.lexeme lexbuf))}
| float { FLOAT (float_of_string (Lexing.lexeme lexbuf))}
| "#start_function" { START_FUNCTION }
| "#end_function" { END_FUNCTION }
(* | "-" { MINUS } *) (* Not sure this is needed *)
| ":" { COLON }
| "," { COMMA }
| "." { DOT }
| "(" { LEFT_PARENTHESIS }
| "(" { RIGHT_PARENTHESIS }
| "[" { LEFT_BRACKET }
| "]" { RIGHT_BRACKET }
| "int-list" { INT_LIST }
| "float-list" { FLOAT_LIST }
| "int" { INT_TYPE }
| "float" { FLOAT_TYPE }
| "void" { VOID_TYPE }
| "assign" { ASSIGN }
| "add" { ADD }
| "sub" { SUB }
| "mult" { MULT }
| "div" { DIV }
| "and" { AND }
| "or" { OR }
| "goto" { GOTO }
| "breq" { BREQ }
| "brneq" { BRNEQ }
| "brlt" { BRLT }
| "brgt" { BRGT }
| "brgeq" { BRGEQ }
| "brleq" { BRLEQ }
| "return" { RETURN }
| "call" { CALL } 
| "callr" { CALLR } 
| "array_store" { ARRAY_STORE } 
| "array_load" { ARRAY_LOAD }


(* This comes after all the specific ones because in case of match conflict, earlier one is picked *)
| id as i { ID (i)}
| _ { raise (SyntaxError ("Unexpected char: " ^ Lexing.lexeme lexbuf)) }
| eof {EOF}