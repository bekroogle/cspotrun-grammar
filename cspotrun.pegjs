//test
{ 
  pegedit_opts = {treenav:"collapse"};
  return_val = [];
  // Removes D3js's  circular references so that the tree can be
  // stringified.
  var decircularize = function(graph) {
    if (graph.parent) {
      delete graph['parent'];
    }

    if (graph.children) {
      for (var i = 0; i < graph.children.length; i++) {
        decircularize(graph.children[i]);
      }
    }
  };

  // Removes the child_objs fields (which are somewhat redundant) from a
  // syntax tree.
  remove_child_objs = function(ast) {
    if (ast.child_objs) {
      delete ast['child_objs'];
    }

    if (ast.children) {
      for (var i = 0; i < ast.children.length; i++) {
        remove_child_objs(ast.children[i]);
      }
    }
  };

  symbol_table = {
    // Insert an entry into the symbol table.
    insert: function(ast) {

      // Set the type field:
      this[ast.child_objs["id"]] = {"type": ast.child_objs["typename"]}
      
      // Set the val field, coercing as necessary, based on the type field:
      switch (this[ast.child_objs["id"]].type) {
        case "int"  : this[ast.child_objs["id"]].val = parseInt(traverse(ast.child_objs["value"])); break;
        case "real" : this[ast.child_objs["id"]].val = parseFloat(traverse(ast.child_objs["value"])); break;
        case "text" : {
          var value = traverse(ast.child_objs.value);
          if (value === null) {
            this[ast.child_objs["id"]].val = null;    
          } else {
            this[ast.child_objs["id"]].val = value.toString();
          }
          break;
        }
        case "list" : this[ast.child_objs["id"]].val = traverse(ast.child_objs["value"]); break;
      }
    },
    lookup: function(key) {
      return this[key].val;
    },
    li_lookup: function(key, index) {
      return this[key].val[index];
    },
    type_of: function(key) {
      return this[key].type;
    },
    proc: function(ast) {
      decircularize(ast.child_objs["body"]);
      this[ast.child_objs["id"]] = {"type": "procedure", "val": ast.child_objs["body"]};
    } 
  };
  var traverse_add = function(ast) {
    return traverse(ast.child_objs["left"]) + 
      traverse(ast.child_objs["right"]);
  };
  var traverse_assign = function(ast) {
    var id = ast.child_objs.id.name
    if (!symbol_table[id]) {
      throw ({
        name: "SyntaxWarning",
        line: ast.line,
        column: ast.column,
        message: "Undeclared variable: " + id + "."
      });
    }
    console.log("assign ast: ");
    console.log(ast);

    switch (symbol_table[id].type) {
      case "int"   : symbol_table[id].val = parseInt(traverse(ast.children[1]));   break;
      case "real"  : symbol_table[id].val = parseFloat(traverse(ast.children[1])); break;
      case "text"  : symbol_table[id].val = traverse(ast.children[1]).toString();  break;
      default      : symbol_table[id].val = traverse(ast.children[1]);             break;
    }
  };
  var traverse_bool_lit = function(ast) {
    if (ast.name === "true") return true;
    else return false;
  };
  var traverse_csv = function(ast) {

  };
  var traverse_declare = function(ast) {
    ast["child_objs"]["value"] = {construct: "null", name: null};
    symbol_table.insert(ast);
  };
  var traverse_divide = function(ast) {
    // This multiplies the numerator and denominator because the denominator
    // will have been converted into the reciprocal of the denominator:
    return traverse(ast.child_objs["numerator"]) * traverse(ast.child_objs.denominator);
  };
  var traverse_if_else = function(ast) {
    if (traverse(ast.child_objs["if_part"].child_objs["condition"])) {
      return traverse(ast.child_objs["then_part"]);
    } else {
      return traverse(ast.child_objs["else_part"]);
    }
  };
  var traverse_if_then = function(ast) {
    if (traverse(ast.child_objs["if_part"].child_objs["condition"])) {
      return traverse(ast.child_objs["then_part"]);
    }
  };
  var traverse_initialize = function(ast) {
    symbol_table.insert(ast);
    // symbol_table[ast.child_objs["id"]] = { "type": ast.child_objs["typename"], "val": traverse(ast.child_objs["value"])};
  };
  var traverse_loop_stmt = function(ast) {
    while (traverse(ast.child_objs["condition"])) {
      ast.return_val.push(traverse(ast.child_objs["body"]));
    }

    // for (var i = 0; i < return_stack.length; i++) {
    //   return_val.push(return_stack[i]);
    // }
    return ast.return_val.join('');
  };
  var traverse_list_elem = function(ast) {
    var val_list = symbol_table.lookup(ast.child_objs["id"].name);
    var spec_list = ast.child_objs["spec"];
    var elem_string = "val_list" + spec_list;
    return eval(elem_string);
  };
  var traverse_list_item = function(ast) {
    return symbol_table.li_lookup(ast.child_objs["id"].name, traverse(ast.child_objs["index"]));
  };
  var traverse_list_item_assign = function(ast) {
    var li_id = ast.child_objs.id;
    var li_index = traverse(ast.child_objs.index);
    var new_value = traverse(ast.child_objs.value);
    symbol_table[li_id].val[li_index] = new_value;
  };
  var traverse_list_lit = function(ast) {
    var list = [traverse(ast.child_objs["head"])];

    if (ast.child_objs["tail"]) {
      for (var i = 0; i< ast.child_objs["tail"].length; i++) {
        list.push(traverse(ast.child_objs["tail"][i]));
      }
    }
    return list;
  };
  var traverse_mod = function(ast) {
    return traverse(ast.child_objs["num"]) % traverse(ast.child_objs["denom"]);
  };
  var traverse_mult = function(ast) {
    return traverse(ast.child_objs["left"]) * traverse(ast.child_objs["right"]);
  };
  var traverse_negative = function(ast) {
    
    return -1 * traverse(ast.child_objs.number);
    // First we convert to string to check for a decimal
    // to infer type (float/int) and coerce back to the
    // appropriate type.
    // var neg_name = ast.name.toString();
    // if (neg_name.match(/\./)) {
    //   neg_name = parseFloat(ast.name);
    // } else {
    //   neg_name = parseInt(ast.name);
    // }

    // // Then we return the coerced result.
    // return traverse({construct: "number", name: neg_name});
  };
  var traverse_number = function(ast) {
    return ast.name
  };
  var traverse_num_var = function(ast) {
    return symbol_table.lookup(ast.name);
  };
  var traverse_print_stmt = function(ast) {
    return traverse(ast.child_objs["expression"]);
  };
  var traverse_prompt_stmt = function(ast) {
    return prompt(traverse(ast.child_objs["expression"]));
  };
  var traverse_proc_call = function(ast) {
    return traverse(symbol_table.lookup(ast.child_objs["id"]));
  };
  var traverse_proc_def = function(ast) {
    symbol_table.proc(ast);
  };
  var traverse_program = function(ast) {
    if (ast.children) {
      for (var stmt in ast.children) {
        ast.return_val.push(traverse(ast.children[stmt]));
      }
    }

    for (var i = 0; i < ast.return_val.length; i++) {
      if (ast.return_val[i] === undefined) {
        ast.return_val.splice(i, 1);
      }
    }
    return ast.return_val.join('');
  };
  var traverse_recip = function(ast) {
    return 1 / traverse(ast.child_objs["denominator"]);
  };
  var traverse_relational_expr = function(ast) {
    l = traverse(ast.child_objs["l"]);
    r = traverse(ast.child_objs["r"]);

    switch (ast.child_objs["operator"]) {  
      case '<='    : return l <= r;  
      case '<'     : return l < r;  
      case '>='    : return l >= r; 
      case '>'     : return l > r; 
      case '='     : return l === r;
      case '<>'    : // falls through
      case '!='    : return l != r;
      default      : throw("Non-implemented relational operator."); 
    }
  };
  var traverse_string_expr = function(ast) {
    return ast.name;
  };
  var traverse_string_cat = function(ast) {
    var new_string = traverse(ast.child_objs["l"]) + traverse(ast.child_objs["r"]);
    return new_string;
  };
  var traverse_string_var = function(ast) {
    
      return symbol_table.lookup(ast.name);
    
  };
  
  traverse = function(ast) {
    ast.return_val = [];
    if (ast.construct) {
      switch (ast.construct) {
        case "add"              : return traverse_add(ast);
        case "assign"           : return traverse_assign(ast);
        case "bool_lit"         : return traverse_bool_lit(ast);
        case "comment"          : return null;
        case "csv"              : return traverse_csv(ast);
        case "declare"          : return traverse_declare(ast);
        case "divide"           : return traverse_divide(ast);
        case "if_else"          : return traverse_if_else(ast);
        case "if_then"          : return traverse_if_then(ast);
        case "initialize"       : return traverse_initialize(ast);
        case "list_elem"        : return traverse_list_elem(ast);
        case "list_item"        : return traverse_list_item(ast);
        case "list_item_assign" : return traverse_list_item_assign(ast);
        case "list_lit"         : return traverse_list_lit(ast);
        case "loop_stmt"        : return traverse_loop_stmt(ast);
        case "mod"              : return traverse_mod(ast);
        case "multiply"         : return traverse_mult(ast);
        case "negative"         : return traverse_negative(ast);
        case "null"             : return null;
        case "number"           : return traverse_number(ast);
        case "print_stmt"       : return traverse_print_stmt(ast);
        case "proc_call"        : return traverse_proc_call(ast);
        case "proc_def"         : return traverse_proc_def(ast);
        case "program"          : return traverse_program(ast);
        case "prompt_stmt"      : return traverse_prompt_stmt(ast);
        case "recip"            : return traverse_recip(ast);
        case "relational_expr"  : return traverse_relational_expr(ast);
        case "string_cat"       : return traverse_string_cat(ast);
        case "string_expr"      : return traverse_string_expr(ast);
        case "string_var"       : return traverse_string_var(ast);
        case "variable"         : return traverse_num_var(ast);
        default: console.error("AST Traversal error: ");
      }
    }
  }
}
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Grammar:                                                                *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

program        = WS stmts:statement* { return {construct: "program", name: "program", children: stmts}; }

statement "statement" = stmt:( label_stmt
                      / proc_def            /* proc myproc: <stmts> end proc */
                      / proc_call           /* do myproc */
                      / goto_stmt
                      / declare_stmt        /* int i [or] int i = 3 */
                      / assign_stmt         /* let i = i + 1 */
                      / ifthen_stmt         /* if i < 2: <stmts> end if */
                      / loop_stmt           /* while i < 2: <stmts> repeat */
                      / print_stmt) WSNL { return stmt; } /* print 2+2 */


line_comment "comment"= HASH (!NL .)* WSNL

/* * * * * * * * * * * * * * * * * * 
 * PROCEDURE CONSTRUCTS            *
 * * * * * * * * * * * * * * * * * */

proc_def "procedure" 
                 = head:proc_header body:proc_body end_proc { return {construct: "proc_def", name: "proc", child_objs: {id: head.name, "body": body}, children: [head, body]};}

proc_header      = PROC i:ID COLON WSNL { return i; }

proc_body        = stmts:statement* { return {construct: "program", name: "proc body", children: stmts};}

end_proc         = END PROC

proc_call "procedure call"
                 = DO proc:ID { return { construct: "proc_call", name: "call", children: [proc], child_objs: {"id": proc.name}}; }

label_stmt       = l:label { return {construct: "label_stmt", name: l.name}; }

label            = LESS i:ID GREATER { return i; }

goto_stmt        = GOTO l:label { return { name: "goto", child_objs: {label: l}, children: [l]}; }

/* * * * * * * * * * * * * * * * * * 
 * VARIABLE HANDLING CONSTRUCTS    *
 * * * * * * * * * * * * * * * * * */

declare_stmt "declaration"
                = initialize
                 / declare

initialize       = t:typename WS i:ID a:assign_pred { return { construct: "initialize", name: "initialize", child_objs: {typename: t.name, id: i.name, value: a}, children: [t, i, a]};}

declare          = t:typename WS i:ID { return { construct: "declare", name: "declare", child_objs: {typename: t.name, id: i.name}, children: [t, i]}; }

assign_pred      = ASSIGN_OP e:expr { return e; }

assign_stmt "assignment"
                 = LET i:ID ASSIGN_OP e:expr { return {construct: "assign", name: "assign", line: line(), column: column(), child_objs: {id: i, value: e}, children: [i, e]}; }
                 / LET li:list_item ASSIGN_OP e:expr { return { construct: "list_item_assign", name: "li_assign", "line": line(), "column": column(), child_objs: {id: li.child_objs.id.name, index: li.child_objs.index, value: e}, children: [li, e]};}

/* * * * * * * * * * * * * * * * * * 
 * CONDITIONAL EXECUTION CONSTRUCTS*
 * * * * * * * * * * * * * * * * * */

// If-then construct
ifthen_stmt "if then"
               = if_else_stmt
               / if_stmt

if_else_stmt   = ip:if_part tp:then_part ep:else_part end_if { return { construct: "if_else", name: "if_else", child_objs: {if_part: ip, then_part: tp, else_part: ep}, children: [ip, tp, ep]};}
if_stmt        = ip:if_part tp:then_part end_if              { return { construct: "if_then", name: "if_then", child_objs: {if_part: ip, then_part: tp}, children: [ip, tp]};}

if_part        = IF cond:bool_expr WS { return {construct: "cond", name: "cond", child_objs: {condition: cond}, children: [cond]};}

then_part      = THEN? WSNL stmts:statement* { return {construct: "program", name: "then part", children: stmts};}

else_part      = ELSE WSNL stmts:statement* { return {construct: "program", name: "else part", children: stmts};}

end_if         = END IF 

// Loop construct
loop_stmt "loop"
               = lh:loop_header lb:loop_body el:end_loop { return {construct: "loop_stmt", name: "loop", child_objs: {condition: lh, body: lb}, children: [lh, lb]}; }

loop_header    = WHILE cond:bool_expr COLON? WSNL{ return cond;}

loop_body      = stmts:statement* { return {construct: "program", name: "loop body", children:  stmts}; }

end_loop       = REPEAT

/* * * * * * * * * * * * * * * * * * 
 * I/O CONSTRUCTS                  *
 * * * * * * * * * * * * * * * * * */
print_stmt "print statement"    
               = PRINT e:expr { return { construct: "print_stmt", name: "print", child_objs: {expression: e}, children: [e]}; }

prompt_stmt "prompt"
               = PROMPT s:prime_expr { return {construct: "prompt_stmt", name: s.name, child_objs: {expression: s}, children: [s]};}

/* * * * * * * * * * * * * * * * * * 
 * EXPRESSIONS                     *
 * * * * * * * * * * * * * * * * * */

// Arithmetic expressions:
//   Left associative operations are refactored into 
//   commutative operations algebraically. (Subract => add a negative,
//   divide => multiply by reciprocal).
expr           = prompt_stmt
               / prime_expr
               / list_lit
               

list_lit       = OPEN_BRACKET head:expr tail:comma_sep_expr* CLOSE_BRACKET { return {construct: "list_lit", name: "list", child_objs: {"head": head, "tail": tail}, children: [head, tail]};}

comma_sep_expr = COMMA e:expr { return e; }

string_cat     = l:string_expr PLUS r:string_cat {return {construct: "string_cat", name: '+', child_objs: {"l": l, "r": r}, children: [l,r]};}
               / string_expr

string_expr    = string_lit
               / ENDL { return {construct: "string_expr", name: "\n"}; } 
               / string_var

string_lit "string literal"
               = double_quoted_str
               / single_quoted_str

double_quoted_str
               = string:(DBL_QUOTE dbl_quo_str_part DBL_QUOTE) WS { var myre = /\"/g; return { construct: "string_expr", name: string.join('').replace(myre, "")};}

single_quoted_str
               = string:(QUOTE quo_str_part QUOTE) WS { var myre = /\'/g; return { construct: "string_expr", name: string.join('').replace(myre, "")};}

string_var     = id:ID &{true} {return {construct: "string_var", name: id.name};}

dbl_quo_str_part
               = n:(! DBL_QUOTE .)* { return text(); }

quo_str_part   = n:(! QUOTE .)* { return text(); }
 
prime_expr     = add

add            = l:subtract PLUS r:add { return { construct: "add", name: "+", child_objs: {left: l, right: r}, children:[l, r]}; }
               / subtract
 
subtract       = l:neg r:subtract { return {construct: "add", name: '+', child_objs: {left: l, right: r}, children: [l, r]};}
               / neg
               
               // Little hack here to display negatives, instead of more complicated tree.  
neg            = MINUS n:mult { return {construct: "multiply", name: "*", child_objs: {left: {construct: "number", name: -1}, right: n}, children: [{construct: "number", name: -1}, n]} ;}
               / mult

mult           = l:mod TIMES r:mult { return {construct: "multiply", name: "*", child_objs: {left: l, right: r}, children: [l, r]}; }
               / mod

mod            = num:div MOD denom:div { return {construct: "mod", name: "mod", child_objs: {"num": num, "denom": denom}, children: [num, denom]};}
               / div

 
div            = num:recip denom:div { return {construct: "divide", name: '*', child_objs: {numerator: num, denominator: denom}, children: [num, denom]}; }
               / recip
 
               // Little hack here to display reciprocals, instead of more complicated tree. 
recip          = DIVIDE n:atom { return {construct: "recip", name: "/", child_objs: {numerator: {construct: "number", name: 1}, denominator: n}, children:[{construct: "number", name: 1}, n]};}
               / parens
 
parens         = OPEN_PAREN a:add CLOSE_PAREN { return a; }
               / atom
               
atom           = n:num_lit { return {construct: "number", name: n}; }
               / var

num_lit        = f:float { return parseFloat(f); }
               / i:integer { return parseInt(i); }

float  "real"  = DIGIT* SPOT DIGIT+   WS  { return text().trim(); }

integer "integer" 
               = d:DIGIT+             WS  { return text().trim(); }

var            = list_elem

list_elem      = i:ID spec:(list_rest) { return { construct: "list_elem", name: i.name, child_objs: {"id": i, "spec": spec}, children: [spec]};}
               / single

list_rest      = list_index+ { return text(); }

list_index     = OPEN_BRACKET index:expr CLOSE_BRACKET


list_item       = i:ID OPEN_BRACKET index:expr CLOSE_BRACKET { return { construct: "list_item", name: "list item", child_objs: {id: i, "index": index}, children: [i, index]}; }
                
single          = i:ID {return {construct: "variable", name: i.name};}
                / string_cat

// Boolean expressions:
bool_expr      = b:bool_lit {return {construct: "bool_lit", name: b};}
               / r:relational_expr 

bool_lit       = TRUE 
               / FALSE 

relational_expr= l:expr op:rel_op r:expr {return {construct: "relational_expr", name: op, child_objs: {operator: op, "l": l, "r": r}, children: [l, r]};}

rel_op         = NOT_EQUAL / EQUALS / GREATER_EQUAL / GREATER / LESS_EQUAL / LESS

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * LEXICAL PART                                            *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
// List of reserved words.  
keywords       =  DO / END / ENDL / FALSE / GOTO / IF / LET / PRINT / PROC / PROMPT / REPEAT / THEN / TRUE /  WHILE / typename

typename      = tn:(TEXT / INT / REAL / LIST) { return {name: tn};}


// Identifier for variables, labels, etc. FolloWS C++ rules.
ID "identifier" = ! keywords i:([_a-zA-Z][_a-zA-Z0-9]*) WS { return{ construct: "id", name: text().trim()}; }

DIGIT          = [0-9]

// Punctuation:
CLOSE_BRACKET  = operator:']'  WS  { return operator; }
COLON          = operator:':'  WS  { return operator; }
COMMA          = operator:","  WS  { return operator; }
DBL_QUOTE      = operator:'"'      { return operator; }
HASH           = operator:"#"      { return operator; }
OPEN_BRACKET   = operator:'['  WS  { return operator; }
SPOT "decimal" = operator:'.'  WS  { return operator; }
QUOTE          = operator:"'"      { return operator; }

// Arithmetic operators:
ASSIGN_OP      = operator:'='  WS  { return operator; }
CLOSE_PAREN    = operator:')'  WS  { return operator; }
DIVIDE         = operator:'/'  WS  { return operator; }
MINUS          = operator:'-'  WS  { return operator; }
MOD            = operator:'%'  WS  { return operator; }
OPEN_PAREN     = operator:'('  WS  { return operator; }
PLUS           = operator:'+'  WS  { return operator; }
TIMES          = operator:'*'  WS  { return operator; }

// Comparison operators:
EQUALS         = '='           WS  { return text().trim(); }
GREATER_EQUAL  = '>='          WS  { return text().trim(); }
GREATER        = '>'           WS  { return text().trim(); }
LESS_EQUAL     = '<='          WS  { return text().trim(); }
LESS           = '<'           WS  { return text().trim(); }
NOT_EQUAL      = ('<>' / '!=') WS  { return text().trim(); }

// Keywords
DO             = 'do'          WS  { return text().trim(); }
ELSE           = 'else'        WS  { return text().trim(); }
END            = 'end'         WS  { return text().trim(); }
ENDL           = 'endl'        WS  { return text().trim(); }
FALSE          = 'false'       WS  { return text().trim(); }
GOTO           = 'goto'        WS  { return text().trim(); }
IF             = 'if'          WS  { return text().trim(); }
LET            = 'let'         WS  { return text().trim(); }
PRINT          = 'print'       WS  { return text().trim(); }
PROC           = 'proc'        WS  { return text().trim(); }
PROMPT         = 'prompt'      WS  { return text().trim(); }
REPEAT         = 'repeat'      WS  { return text().trim(); }
THEN           = 'then'        WS  { return text().trim(); }
TRUE           = 'true'        WS  { return text().trim(); }
WHILE          = 'while'       WS  { return text().trim(); }

// Typenames
INT            = 'int'         WS  { return text().trim(); }
LIST           = 'list'        WS  { return text().trim(); }
REAL           = 'real'        WS  { return text().trim(); }
TEXT           = 'text'        WS  { return text().trim(); }

// Whitespace (space, tab, newline)*
WS             = WHITESPACE*
WHITESPACE "whitespace"    = [ \t]
               /line_comment
NL             = [\n\r]
WSNL           = (WHITESPACE/NL)*
