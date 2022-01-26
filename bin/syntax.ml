type irType = 
  | ArrayType of irType * int
  | FloatType
  | IntType

type dataListEntry = 
  | VarData of string
  | ArrayData of string * int

type operand = 
  | Int of int
  | Float of float
  | Identifier of string

type instruction = 
  | Label of string

  | Assign of string * operand

  | Add of string * operand * operand
  | Sub of string * operand * operand
  | Mult of string * operand * operand
  | Div of string * operand * operand
  | And of string * operand * operand
  | Or of string * operand * operand

  | Goto of string

  | Breq of string * operand * operand
  | Brneq of string * operand * operand
  | Brlt of string * operand * operand
  | Brgt of string * operand * operand
  | Brgeq of string * operand * operand
  | Brleq of string * operand * operand

  | Return of operand

  | Call of string * operand list
  | Callr of string * string * operand list

  | Array_Store of operand * string * int
  | Array_Load of operand * string * int

  | Array_Assign of string * int * operand

type func = {
    (* Fill this *)
    name:string;
    return_type: irType option;
    parameters: (irType * string) list;
    int_list: dataListEntry list;
    float_list: dataListEntry list;
    code_body: instruction list;
}

