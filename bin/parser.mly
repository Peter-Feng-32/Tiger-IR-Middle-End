(* Based on specifications found here: *)
(* https://github.gatech.edu/CS-4240-Spring-2022/Project-1/blob/main/materials/Tiger-IR.pdf *)

%token <string> ID

%token <int> INT
%token <float> FLOAT 

%token START_FUNCTION
%token END_FUNCTION

(* Symbols *)
(* %token MINUS *) (* Not sure this is needed *)
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

(* Tiger IR Types *)
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

(* TODO: Do this in a separate syntax file. Eg: https://github.com/andrejbauer/plzoo/blob/master/src/minihaskell/syntax.ml *)
%{
  open Syntax
%}

(* TigerIR programs are a list of functions *)
(* Let the non-terminal symbol prog be our start symbol *)
(* and convert it into a list of functions *)

(* In other words, our grammar reads the program (prog) and produces a list of functions *)
%start <func list> prog
%%

(* TODO: decide how to parse label.  Each non empty line is label or instr. *)
(* Store code body as a list of instructions and labels? *)
(* Labels get a separate line *)
(* No go: have to define a new type that includes both.  *)

prog: 
  | EOF     { [] }
  | f = func; p = prog { f::p }
  ;

(* REGEX: * is 0 or more, + is 1 or more *)
func: 
  | EOL*; START_FUNCTION; EOL+; signat = signature; dataseg = data_segment; body = code_body; END_FUNCTION; EOL*
    { 
      let (ret, i, p) = signat in 
        let (il, fl) = dataseg in
        { name=i; return_type=ret; parameters=p; int_list=il; float_list=fl; code_body=body }
    }
  ;

signature:  
  | ret = ir_type; i = identifier; LEFT_PARENTHESIS; p = parameters; RIGHT_PARENTHESIS; COLON; EOL+
    { (ret, i, p) }
  ;

parameters: 
  | p = separated_list(COMMA, parameter)
  { p }
  ;

parameter: 
  | t = ir_type; i = identifier;
  { (t, i) }
  ;

data_segment:
  | INT_LIST; COLON; il = data_list; EOL; FLOAT_LIST; COLON; fl = data_list; EOL+;
  { (il, fl) }

data_list: 
  | l = separated_list(COMMA, data_list_entry)
  { l }

data_list_entry:
  | i = identifier
  { VarData(i) }
  | i = identifier; LEFT_BRACKET; size = INT; RIGHT_BRACKET
  { ArrayData(i, size) }
;

(* List of instructions and labels *)
code_body:
  | code = separated_list(EOL, instruction) 
  { code }
  ;

(* Can't just call this type: type is a reserved word *)
(* Need to include handling lists as well *)
ir_type:
  | t = ir_type ; LEFT_BRACKET; i = INT; RIGHT_BRACKET;
    { ArrayType(t, i)}
  | INT_TYPE
    { IntType }
  | FLOAT_TYPE
    { FloatType }
  | VOID_TYPE
    { VoidType } 
  ;


instruction:
(* Probably just hard code all the instruction possibilities here   *)
  |  ASSIGN; COMMA; dest = identifier; COMMA; src = operand
  { Assign(dest, src) }

  |  ADD; COMMA; dest=identifier; COMMA; op1=operand; COMMA; op2=operand
  { Add(dest, op1, op2) }
  |  SUB; COMMA; dest=identifier; COMMA; op1=operand; COMMA; op2=operand
  { Sub(dest, op1, op2) }
  |  MULT; COMMA; dest=identifier; COMMA; op1=operand; COMMA; op2=operand
  { Mult(dest, op1, op2) }
  |  DIV; COMMA; dest=identifier; COMMA; op1=operand; COMMA; op2=operand
  { Div(dest, op1, op2) }
  |  AND; COMMA; dest=identifier; COMMA; op1=operand; COMMA; op2=operand
  { And(dest, op1, op2) }
  |  OR; COMMA; dest=identifier; COMMA; op1=operand; COMMA; op2=operand
  { Or(dest, op1, op2) }

  |  GOTO; COMMA; dest=identifier
  { Goto(dest) }

  |  BREQ; COMMA; dest=identifier; COMMA; op1=operand; COMMA; op2=operand
  { Breq(dest, op1, op2) }
  |  BRNEQ; COMMA; dest=identifier; COMMA; op1=operand; COMMA; op2=operand
  { Breq(dest, op1, op2) }
  |  BRLT; COMMA; dest=identifier; COMMA; op1=operand; COMMA; op2=operand
  { Breq(dest, op1, op2) }
  |  BRGT; COMMA; dest=identifier; COMMA; op1=operand; COMMA; op2=operand
  { Breq(dest, op1, op2) }
  |  BRGEQ; COMMA; dest=identifier; COMMA; op1=operand; COMMA; op2=operand
  { Breq(dest, op1, op2) }
  |  BRLEQ; COMMA; dest=identifier; COMMA; op1=operand; COMMA; op2=operand
  { Breq(dest, op1, op2) }

  | RETURN; COMMA; op=operand 
  { Return(op) } 

  | CALL; COMMA; op1=identifier
  { Call(op1, []) }
  | CALL; COMMA; op1=identifier; COMMA; args=arguments
  { Call(op1, args) }

  | CALLR; COMMA; op1=identifier; COMMA; op2=identifier
  { Callr(op1, op2, []) }
  | CALLR; COMMA; op1=identifier; COMMA; op2=identifier; COMMA; args=arguments
  { Callr(op1, op2, args) }

  | ARRAY_STORE; COMMA; op1=operand; COMMA; arr=identifier; COMMA; index=operand
  { Array_Store(op1, arr, index) }

  | ARRAY_LOAD; COMMA; op1=operand; COMMA; arr=identifier; COMMA; index=operand
  { Array_Load(op1, arr, index) }

  | ASSIGN; COMMA; arr=identifier; COMMA; size=INT; COMMA; value=operand
  { Array_Assign(arr, size, value) }
  ;

arguments:
  | args = separated_list(COMMA, operand)
  { args }
;
operand:
  | i = INT
  { Int(i)}
  | f = FLOAT
  { Float(f) }
  | i = identifier
  { Identifier(i) }
;

identifier:
  | i = ID 
  { i }
  ;




%%