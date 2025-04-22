%lex
%%

\s+                                     /* Ignora espaços em branco */
int\b                                   { return 'INT'; }
double\b                                { return 'DOUBLE'; }
float\b                                 { return 'FLOAT'; }
char\b                                  { return 'CHAR'; }
if\b                                    { return 'IF'; }
else\b                                  { return 'ELSE'; }
switch\b                                { return 'SWITCH'; }
case\b                                  { return 'CASE'; }
break\b                                 { return 'BREAK'; }
default\b                               { return 'DEFAULT'; }
while\b                                 { return 'WHILE'; }
for\b                                   { return 'FOR'; }
do\b                                    { return 'DO'; }
printf\b                                { return 'PRINTF'; }
scanf\b                                 { return 'SCANF'; }
malloc\b                                { return 'MALLOC'; }
sizeof\b                                { return 'SIZEOF'; }
free\b                                  { return 'FREE'; }
typedef\b                               { return 'TYPEDEF'; }
struct\b                                { return 'STRUCT'; }
union\b                                 { return 'UNION'; }
enum\b                                  { return 'ENUM'; }
void\b                                  { return 'VOID'; }
const\b                                 { return 'CONST'; }
volatile\b                              { return 'VOLATILE'; }
signed\b                                { return 'SIGNED'; }
unsigned\b                              { return 'UNSIGNED'; }
register\b                              { return 'REGISTER'; }
long\b                                  { return 'LONG'; }
short\b                                 { return 'SHORT'; }
var\b                                   { return 'VAR'; }
"#"                                     { return '#'; }
define\b                                { return 'DEFINE'; }
include\b                               { return 'INCLUDE'; }
return\b                                { return 'RETURN'; }

[a-zA-Z_][a-zA-Z0-9_]*(\.[a-zA-Z_][a-zA-Z0-9_]*)+  { yytext = yytext; return 'IDF'; }

"//"[^\n]*                              {}
'/*'[^\n]*'*/'                          {}
\<[a-zA-Z0-9_]+.[a-zA-Z0-9_]+\>            {return 'library';}

"=="                                    { return 'EQ'; }
"!="                                    { return 'NE'; }
"<="                                    { return 'LE'; }
">="                                    { return 'GE'; }
"<"                                     { return '<'; }
">"                                     { return '>'; }

"&&"                                    { return 'AND'; }
"&"                                     { return 'AMP'; }
"||"                                    { return 'OR'; }
"!"                                     { return 'NOT'; }

\"([^"\\]|\\.)*\"                      { yytext = yytext.slice(1,-1); return 'STR_LIT'; }

\-?([0-9]+)?\.([0-9]*)([eE][+-]?[0-9]+)?     { yytext = parseFloat(yytext); return 'F_LIT'; }

\-?[0-9]+                              { yytext = Number(yytext); return 'INT_LIT'; }


(\')[a-zA-Z0-9_!@#$%¨&*()/?](\')				{ yytext = yytext.slice(1,-1); return 'C_LIT'; }
(\")[a-zA-Z0-9_!@#$%¨&*()/?](\")				{ yytext = yytext.slice(1,-1); return 'C_LIT'; }

[a-zA-Z_][a-zA-Z0-9_]*                 { return 'IDF'; }

"+"                                    { return 'SUM'; }
"-"                                    { return 'SUB'; }
"*"                                    { return 'MULT'; }
"/"                                    { return 'DIV'; }
"%"                                    { return 'RDIV'; }  Operadores aritméticos */
"="                                     { return 'ATT'; }    /* Operador de atribuição */
":"                                     { return ':'; }    /* Dois-pontos para casos em switch */
"("                                     { return '('; }
")"                                     { return ')'; }
"["                                     { return '['; }
"]"                                     { return ']'; }
"{"                                     { return '{'; }
"}"                                     { return '}'; }
";"                                     { return ';'; }
","                                     { return ','; }
"."                                     { return '.'; }
"\""                                    { return 'DQUOTE'; }
"\'"                                    { return 'QUOTE'; }
.                                       { console.log('Unrecognized token:', yytext); return 'INVALID'; } /* Debug para tokens inválidos */


/lex

// Parser (parte que define a gramática)
%start program

%%

program
    : statement_list
    | /* vazio */
    ;

statement_list
    : statement_list statement
    | statement
    | /* vazio */
    ;

statement
    : '#' 'INCLUDE' 'library' 
    | type declarator '(' ')' block
    | type declarator '(' param_list_opt ')' block
    | type declarator '(' param_list_opt ')' ';'
    | declaration
    | 'ENUM' IDF '{' enumerator_list '}' ';'
    | 'TYPEDEF' type multideclaration ';'
    | 'STRUCT' IDF '{' struct_member_list '}' ';'
    | 'STRUCT' IDF ';'
    | 'UNION' IDF '{' struct_member_list '}' ';'
    | 'UNION' IDF ';'
    | 'PRINTF' '(' argument_list ')' ';'
    | 'SCANF' '(' argument_list ')' ';'
    | 'MALLOC' '(' argument_list ')' ';'
    | 'FREE' '(' argument_list ')' ';'
    | IDF '(' argument_list ')' ';'
    | 'RETURN' expression ';'
    | assignment ';'
    | operation_idf ';'
    | if_statement
    | while_statement
    | for_statement
    | switch_statement
    | do_while_statement
    | block
    | ';'
    ;

type 
    : 'STRUCT' IDF
    | 'UNION' IDF
    | 'ENUM' IDF
    | 'REGISTER' type
    | 'CONST' type
    | 'VOLATILE' type
    | 'SIGNED' type
    | 'UNSIGNED' type
    | 'LONG' type
    | 'SHORT' type
    | 'INT'
    | 'DOUBLE'
    | 'FLOAT'
    | 'CHAR'
    | 'VOID'
    ;

declaration
    : type multideclaration ';'
    | '#' 'DEFINE' 'IDF' expression
    ;

declarator
    : 'IDF'
    | MULT declarator   /* *arr, **p, etc */
    | declarator '[' expression ']'
    ;

multideclaration
    : declarator
    | declarator 'ATT' expression
    | multideclaration ',' declarator
    | multideclaration ',' assignment 'ATT' expression
    ;

assignment
    : 'IDF' 'ATT' expression
    | 'IDF' '[' expression ']' 'ATT' expression
    ;

operation_idf
    : 'IDF' 'SUM' 'ATT' expression
    | 'IDF' 'SUB' 'ATT' expression
    | 'IDF' 'MULT' 'ATT' expression
    | 'IDF' 'DIV' 'ATT' expression
    | 'IDF' 'SUM' 'SUM'
    | 'IDF' 'SUB' 'SUB'
    ;

argument_list
    : /*vazio*/
    |nonempty_args
    ;

nonempty_args
    : expression
    | nonempty_args ',' expression
    ;

param_list_opt
    : /* vazio */
    | param_list
    ;

param_list
    : type declarator
    | param_list ',' type declarator
    ;

struct_member_list
    :declaration
    | struct_member_list declaration
    ;

enumerator_list
    : IDF
    | enumerator_list ',' IDF
    ;

if_statement
    : 'IF' '(' expression ')' statement
    | 'IF' '(' expression ')' statement 'ELSE' statement
    ;

while_statement
    : 'WHILE' '(' expression ')' statement
    ;

for_statement
    : 'FOR' '(' declaration expression_opt ';' assignment_opt ')' block
    | 'FOR' '(' assignment_opt ';' expression_opt ';' operation_idf ')' block
    ;

assignment_opt
    : assignment
    | operation_idf
    | DIVMULT vazio MULTDIV
    | 'IDF'
    ;

expression_opt
    : expression
    | DIVMULT vazio MULTDIV
    ;

switch_statement
    : 'SWITCH' '(' expression ')' '{' case_list '}'
    ;

case_list
    : 'CASE' 'INT_LIT' ':' statement_list 'BREAK' ';' case_list
    | 'CASE' 'INT_LIT' ':' statement_list 'BREAK' ';'
    | 'CASE' 'INT_LIT' ':' statement_list case_list
    | 'CASE' 'INT_LIT' ':' statement_list
    | 'CASE' expression ':' statement_list 'BREAK' ';' case_list
    | 'CASE' expression ':' statement_list 'BREAK' ';'
    | 'CASE' expression ':' statement_list case_list
    | 'CASE' expression ':' statement_list
    | case_list 'DEFAULT' ':' statement_list 'BREAK' ';'
    | 'DEFAULT' ':' statement_list 'BREAK' ';'
    | 'DEFAULT' ':' statement_list
    |
    ;

do_while_statement
    : 'DO' statement 'WHILE' '(' expression ')' ';'
    ;

block
    : '{' statement_list '}'
    ;

expression
    : 'SIZEOF' '(' type ')'
    | 'SIZEOF' expression
    | 'AMP' expression
    | '(' type 'MULT' ')' expression
    | '(' type ')' expression 
    | '(' type declarator ')' expression
    | expression 'SUM' expression
    | expression 'SUB' expression
    | expression 'MULT' expression
    | expression 'DIV' expression
    | expression 'RDIV' expression
    | expression 'EQ' expression
    | expression 'NE' expression
    | expression 'LE' expression
    | expression 'GE' expression
    | expression '<' expression
    | expression '>' expression
    | expression 'AND' expression
    | expression 'OR' expression
    | 'NOT' expression
    | '(' expression ')'
    | '{' values '}'
    | 'INT_LIT'
    | 'STR_LIT'
    | 'SCANF' '(' argument_list ')'
    | 'F_LIT'
    | 'C_LIT'
    | 'IDF'
    | '(' 'type' ')' 'IDF'
    | expression '.' 'IDF'
    | 'IDF' '[' expression ']'
    | 'MALLOC' '(' argument_list ')'
    | 'FREE' '(' argument_list ')'
    ;

values
    : values ',' expression
    | expression
    ; 


%%