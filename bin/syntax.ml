type irType = 
  | ArrayType of irType * int
  | FloatType
  | IntType

type dataListEntry = 
  | VarData of string
  | ArrayData of string * int

type instr_or_label = 
  | Label of string

type func = {
    (* Fill this *)
    name:string;
    return_type: irType option;
    parameters: (irType * string) list;
    int_list: dataListEntry list;
    float_list: dataListEntry list;
    code_body: instr_or_label list;
}
