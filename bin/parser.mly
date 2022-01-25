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


