(* Based on specifications found here: *)
(* https://github.gatech.edu/CS-4240-Spring-2022/Project-1/blob/main/materials/Tiger-IR.pdf *)

%token <string> ID

%token <int> INT
%token <float> FLOAT 

%token START_FUNCTION
%token END_FUNCTION

(* Symbols *)
%token MINUS
%token COLON
%token COMMA
%token DOT
%token EOF (* End of File *)
%token EOL (* Need EOL because only EOL denotes the end of a statement *)

%token LEFT_PARENTHESIS
%token RIGHT_PARENTHESIS
%token LEFT_BRACKET
%token RIGHT_BRACKET

(* List Types *)
%token INT_LIST
%token FLOAT_LIST

(* Types *)
%token INT_TYPE
%token FLOAT_TYPE
%token VOID_TYPE

(* Ops *) 
%token ASSIGN

%token ADD
%token SUB
%token MULT
%token DIV
%token AND
%token OR

%token GOTO

%token BREQ
%token BRNEQ
%token BRLT
%token BRGT
%token BRGEQ
%token BRLEQ

%token RETURN

%token CALL
%token CALLR

%token ARRAY_STORE
%token ARRAY_LOAD

(* Define custom types for the non-terminal symbols so they can be converted *)
(* Because there are no in-built types representing things in the Tiger-IR *)
(* like functions, instructions, operands, types, etc. *)
type func{
    (* Fill this *)
    
}

(* TigerIR programs are a list of functions *)
(* Let the non-terminal symbol prog be our start symbol *)
(* and convert it into a list of functions *)

(* In other words, our grammar reads the program (prog) and produces a list of functions *)
% start <func list> prog
%%

(* TODO: decide how to parse label.  Each non empty line is label or instr. *)
(* Store code body as a list of instructions and labels? *)

prog: 
  | EOF     { [] }
  | f = func; p = prog { f::p }

(* REGEX: * is 0 or more, + is 1 or more *)
func: 
  | EOL*; START_FUNCTION; EOL+; sig = signature; data = data_segment; body = code_body; END_FUNCTION; EOL*


signature:  

data_segment:

code_body:

instruction:

label:

type:


