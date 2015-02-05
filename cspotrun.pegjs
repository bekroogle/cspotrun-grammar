{ pegedit_opts = 
  { 
    treenav:
      //"zoom";
      //"cluster";
      "collapse"
  };
}
// Grammar:

program        = stmts:statement* { return {construct: "program", name: "program", children: stmts}; }

statement      = label_stmt
               / goto_stmt
               / declare_stmt
               / assign_stmt
               / ifthen_stmt
               / loop_stmt
               / print_stmt

/* * * * * * * * * * * * * * * * * * 
 * GOTO CONSTRUCTS                 *
 * * * * * * * * * * * * * * * * * */

// Target of goto statements.
label_stmt     = l:label { return {construct: "label_stmt", name: l.name}; }

// Used in label_stmt and goto_stmt.
label          = LESS i:ID GREATER { return i; }

// Transfer flow of control to the node of the tree with the given label.
goto_stmt      = GOTO l:label { return { name: "goto", children: [l]}; }

/* * * * * * * * * * * * * * * * * * 
 * VARIABLE HANDLING CONSTRUCTS    *
 * * * * * * * * * * * * * * * * * */

declare_stmt   = initialize
               / declare

initialize   = t:typename WS i:ID a:assign_pred { return { construct: "initialize", name: "initialize", children: [t, i, a]};}

declare = t:typename WS i:ID { return { construct: "declare", name: "declare", children: [t, i]}; }

assign_pred    = ASSIGN_OP e:expr { return e; }

assign_stmt    = list_itm_assign 
               / scalar_assign

list_itm_assign= LET li:list_itm EQUALS e:expr { return { construct: "assign", name: "assign", children: [li, e]};}

scalar_assign  = LET i:ID ASSIGN_OP e:expr { return {construct: "assign", name: "assign", children: [i, e]}; }


/* CONDITIONAL EXECUTION CONSTRUCTS */
// If-then construct
ifthen_stmt    = ip:if_part tp:then_part end_if { return { construct: "if-then", name: "if-then", children: [ip, tp]};}

if_part        = IF cond:bool_expr THEN COLON { return {construct: "cond", name: "cond", children: [cond]};}

then_part      = stmts:statement* { return {construct: "program", name: "then part", children: stmts};}

end_if         = END IF 

// Loop construct
loop_stmt      = lh:loop_header lb:loop_body el:end_loop { return {construct: "loop_stmt", name: "loop", children: [lh, lb]}; }

loop_header    = WHILE cond:bool_expr COLON { return {construct: "cond", name: "cond", children: [cond]}; }

loop_body      = stmts:statement* { return {construct: "program", name: "loop body", children:  stmts}; }

end_loop       = REPEAT

/* I/O CONSTRUCTS */
print_stmt     = PRINT expr

/* * * * * * * * * * * * * * * * * * 
 * EXPRESSIONS                     *
 * * * * * * * * * * * * * * * * * */

// Arithmetic expressions:
//   Left associative operations are refactored into 
//   commutative operations algebraically. (Subract => add a negative,
//   divide => multiply by reciprocal).
expr           = add

add            = l:subtract PLUS r:add { return { construct: "add", name: "+", children:[l, r]}; }
               / subtract
 
subtract       = l:neg r:subtract { return {construct: "add", name: '+', children: [l, r]};}
               / neg
               
               // Little hack here to display negatives, instead of more complicated tree.  
neg            = MINUS n:mult { return {construct: "negative", name: '-' + n.name} ;}
               / mult
 
mult           = l:div TIMES r:mult { return {construct: "multiply", name: "*", children: [l, r]}; }
               / div
 
div            = num:recip denom:div { return {construct: "multiply", name: '*', children: [num, denom]}; }
               / recip
 
               // Little hack here to display reciprocals, instead of more complicated tree. 
recip          = DIVIDE n:number { return {construct: "reciprocal", name: "1/" + n.name}; }
               / parens
 
parens         = OPEN_PAREN a:add CLOSE_PAREN { return a; }
               / number
               
number         = n:num_lit { return {name: n}; }
               / num_var

num_lit        = f:float { return parseFloat(f); }
               / i:integer { return parseInt(i); }

float          = DIGIT* SPOT DIGIT+   WS  { return text().trim(); }

integer        = d:DIGIT+             WS  { return text().trim(); }

num_var        = list_itm
               / scalar_num

list_itm       = i:ID OPEN_BRACKET index:expr CLOSE_BRACKET { return { construct: "list_itm", name: "list item", children: [i, index]}; }

scalar_num     = i:ID


// Boolean expressions:
bool_expr      = bool_lit {return { name: text().trim()}; }
               / relational_expr

bool_lit       = TRUE 
               / FALSE

relational_expr= l:expr op:rel_op r:expr

rel_op         = EQUALS / GREATER_EQUAL / GREATER / LESS_EQUAL / LESS

// List of reserved words.  
keywords       = IF / TRUE / FALSE / THEN / END / PROMPT / GOTO / REPEAT / WHILE

typename       = TEXT / INT / REAL / LIST
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * LEXICAL PART                                            *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
// List of reserved words.  
keywords       = IF / TRUE / FALSE / THEN / END / PROMPT / GOTO / REPEAT / WHILE / LET / typename

typename       = tn:(TEXT / INT / REAL / LIST) { return { name: tn }; }
// Identifier for variables, labels, etc. FolloWS C++ rules.
ID             = ! keywords i:([_a-zA-Z][_a-zA-Z0-9]*) WS { return{ construct: "id", name: text().trim()}; }

DIGIT          = (ZERO/NON_ZERO_DIGIT)
NON_ZERO_DIGIT = [1-9]
ZERO           = [0]

// Punctuation:
COLON          = operator:':'  WS  { return operator; }
CLOSE_BRACKET  = operator:']'  WS  { return operator; }
DBL_QUOTE      = operator:'"'  WS  { return operator; }
OPEN_BRACKET   = operator:'['  WS  { return operator; }
SPOT "decimal" = operator:'.'  WS  { return operator; }

// Arithmetic operators:
ASSIGN_OP      = operator:'='  WS  { return operator; }
CLOSE_PAREN    = operator:')'  WS  { return operator; }
DIVIDE         = operator:'/'  WS  { return operator; }
MINUS          = operator:'-'  WS  { return operator; }
OPEN_PAREN     = operator:'('  WS  { return operator; }
PLUS           = operator:'+'  WS  { return operator; }
TIMES          = operator:'*'  WS  { return operator; }

// Comparison operators:
EQUALS         = '='           WS  { return text().trim(); }
GREATER_EQUAL  = '>='          WS  { return text().trim(); }
GREATER        = '>'           WS  { return text().trim(); }
LESS_EQUAL     = '<='          WS  { return text().trim(); }
LESS           = '<'           WS  { return text().trim(); }

// Keywords
END            = 'end'         WS  { return text().trim(); }
FALSE          = 'false'       WS  { return text().trim(); }
GOTO           = 'goto'        WS  { return text().trim(); }
IF             = 'if'          WS  { return text().trim(); }
LET            = 'let'         WS  { return text().trim(); }
PRINT          = 'print'       WS  { return text().trim(); }
PROMPT         = 'prompt'      WS  { return text().trim(); }
REPEAT         = 'repeat'      WS  { return text().trim(); }
THEN           = 'then'        WS  { return text().trim(); }
TRUE           = 'true'        WS  { return text().trim(); }
WHILE          = 'while'       WS  { return text().trim(); }

// Typenames
INT            = 'int'         WS  { return text().trim(); }
REAL           = 'real'        WS  { return text().trim(); }
TEXT           = 'text'        WS  { return text().trim(); }
LIST           = 'list'        WS  { return text().trim(); }

// Whitespace (space, tab, newline)*
WS             = [ \t\n]*