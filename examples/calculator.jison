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
sizeof\b                                { return 'SIZEOF'; }
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
"%"                                    { return 'RDIV'; }  /* Operadores aritméticos */
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

%start program

%right ATT
%left OR
%left AND
%left '|'
%left AMP
%left EQ NE
%left '<' '>' LE GE
%left SUM SUB
%left MULT DIV RDIV
%right '!' '~'
%right CAST

%{
const { addSymbol, setScope, resetScope } = require('./Syntax/symbolTable');
const { createNode } = require('./Syntax/ast');
const { semanticCheck, inferType } = require('./Syntax/semantic');
const { generateThreeAddress } = require('./Syntax/threeAddress');
%}

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
    // FUNÇÃO COM BLOCO: novo escopo!
    | type declarator '(' param_list_opt ')' func_scope block
    // Função só protótipo (sem bloco): não precisa escopo
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

// Sempre cria escopo novo ao entrar no corpo da função
func_scope
    : /* vazio */ { setScope($-3); }
    ;

type
    : base_type
    | type MULT
    ;

base_type
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
        {
            for (var i = 0; i < $2.length; i++) {
                // Variável simples: int x;
                if (typeof $2[i] === 'string') {
                    addSymbol($2[i], $1);
                } 
                // Inicialização: array ou variável com valor
                else if (Array.isArray($2[i])) {
                    // Array declarado: $2[i][0] é nó AST tipo array
                    if (typeof $2[i][0] === 'object' && $2[i][0].type === 'array') {
                        addSymbol($2[i][0].value, $1 + '[]');
                    } else {
                        addSymbol($2[i][0], $1);
                    }

                    // AST/3-address code:
                    if (Array.isArray($2[i][1])) {
                        // Array inicializado: int arr[5] = { ... };
                        var arrayId = createNode('array', null, null, $2[i][0].value);
                        var astNode = createNode('array_init', arrayId, null, $2[i][1]);
                        semanticCheck(astNode);
                        generateThreeAddress(astNode);
                    } else {
                        // Variável comum inicializada: int x = 1;
                        var nomeVar = (typeof $2[i][0] === 'object' && $2[i][0].type === 'array')
                            ? $2[i][0].value
                            : $2[i][0];
                        var astNode = createNode('assign', createNode('id', null, null, nomeVar), $2[i][1]);
                        semanticCheck(astNode);
                        generateThreeAddress(astNode);
                    }
                }
            }
        }
    | type declarator 'ATT' '{' values '}' ';'
        {
            // int arr[3] = {1,2,3};
            var nomeArr = (typeof $2 === 'object' && $2.type === 'array')
                ? $2.value
                : $2;
            addSymbol(nomeArr, $1 + '[]');
            var arrayId = createNode('array', null, null, nomeArr);
            var astNode = createNode('array_init', arrayId, null, $5);
            semanticCheck(astNode);
            generateThreeAddress(astNode);
        }
    | '#' 'DEFINE' 'IDF' expression
    ;



declarator
    : 'IDF' { $$ = $1; }
    | MULT declarator   { $$ = $2; }
    | declarator '[' expression ']' 
        { $$ = createNode('array', null, null, $1, { size: $3 }); }
    ;



multideclaration
    : declarator                          { $$ = [$1]; }
    | declarator 'ATT' expression         { $$ = [[$1, $3]]; }
    | declarator 'ATT' '{' values '}'     { $$ = [[$1, $4]]; }
    | multideclaration ',' declarator     { $1.push($3); $$ = $1; }
    | multideclaration ',' declarator 'ATT' expression
                                          { $1.push([$3, $5]); $$ = $1; }
    | multideclaration ',' declarator 'ATT' '{' values '}'
                                          { $1.push([$3, $6]); $$ = $1; }
    ;

assignment
    : 'IDF' 'ATT' expression
        {
            var astNode = createNode('assign', createNode('id', null, null, $1), $3);
            if (typeof parser.onAssignment === 'function') {
                parser.onAssignment(astNode);
            }
            semanticCheck(astNode);
            generateThreeAddress(astNode);
        }
    | 'IDF' '[' expression ']' 'ATT' expression
        {
            var arrAccess = createNode('array_access', null, null, { id: $1, index: $3 });
            var astNode = createNode('assign', arrAccess, $6);
            if (typeof parser.onAssignment === 'function') {
                parser.onAssignment(astNode);
            }
            semanticCheck(astNode);
            generateThreeAddress(astNode);
        }
    | 'IDF' '[' expression ']' 'ATT' '{' values '}'
        {
            var arrayId = createNode('array', null, null, $1);
            var astNode = createNode(
                'array_init',
                arrayId,
                $3,
                $7
            );
            if (typeof parser.onAssignment === 'function') {
                parser.onAssignment(astNode);
            }
            semanticCheck(astNode);
            generateThreeAddress(astNode);
        }
    ;


operation_idf
    : IDF SUM ATT expression
        {
            var lhs = createNode('id', null, null, $1);
            var rhs = createNode('bin_op', lhs, $4, '+');
            var astNode = createNode('assign', lhs, rhs);
            semanticCheck(astNode);
            generateThreeAddress(astNode);
        }
    | IDF SUB ATT expression
        {
            var lhs = createNode('id', null, null, $1);
            var rhs = createNode('bin_op', lhs, $4, '-');
            var astNode = createNode('assign', lhs, rhs);
            semanticCheck(astNode);
            generateThreeAddress(astNode);
        }
    | IDF MULT ATT expression
        {
            var lhs = createNode('id', null, null, $1);
            var rhs = createNode('bin_op', lhs, $4, '*');
            var astNode = createNode('assign', lhs, rhs);
            semanticCheck(astNode);
            generateThreeAddress(astNode);
        }
    | IDF DIV ATT expression
        {
            var lhs = createNode('id', null, null, $1);
            var rhs = createNode('bin_op', lhs, $4, '/');
            var astNode = createNode('assign', lhs, rhs);
            semanticCheck(astNode);
            generateThreeAddress(astNode);
        }
    | IDF SUM SUM
        {
            var lhs = createNode('id', null, null, $1);
            var rhs = createNode('int_lit', null, null, 1);
            var expr = createNode('bin_op', lhs, rhs, '+');
            var astNode = createNode('assign', lhs, expr);
            semanticCheck(astNode);
            generateThreeAddress(astNode);
        }
    | IDF SUB SUB
        {
            var lhs = createNode('id', null, null, $1);
            var rhs = createNode('int_lit', null, null, 1);
            var expr = createNode('bin_op', lhs, rhs, '-');
            var astNode = createNode('assign', lhs, expr);
            semanticCheck(astNode);
            generateThreeAddress(astNode);
        }
    ;


argument_list
    : /*vazio*/
    | nonempty_args
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
    : declaration
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


declaration_no_semi
    : type multideclaration
        {
            for (var i = 0; i < $2.length; i++) {
                if (typeof $2[i] === 'string') {
                    addSymbol($2[i], $1);
                } else if (Array.isArray($2[i])) {
                    addSymbol($2[i][0], $1);
                }
            }
            $$ = null;
        }
    ;

for_init
    : declaration_no_semi
    | assignment
    | operation_idf
    | expression
    | /* vazio */
    ;

for_condition
    : expression
    | operation_idf
    | /* vazio */
    ;

for_increment
    : assignment
    | operation_idf
    | /* vazio */
    ;

// Novo escopo para cada for!
for_statement
    : 'FOR' '(' for_scope_enter for_init ';' for_condition ';' for_increment ')' block for_scope_exit
    ;

for_scope_enter
    : /* vazio */ { setScope('for_' + Math.random().toString(36).substr(2,5)); }
    ;
for_scope_exit
    : /* vazio */ { resetScope(); }
    ;

switch_statement
    : 'SWITCH' '(' expression ')' '{' case_list '}'
    ;

case_list
    : 'CASE' 'INT_LIT' ':' statement_list 'BREAK' ';' case_list
    | 'CASE' 'INT_LIT' ':' statement_list 'BREAK' ';'
    | 'DEFAULT' ':' statement_list 'BREAK' ';'
    | 'DEFAULT' ':' statement_list
    ;

do_while_statement
    : 'DO' statement 'WHILE' '(' expression ')' ';'
    ;

block
    : '{' block_enter statement_list '}' block_exit
    ;

block_enter
    : /* vazio */ { setScope('block_' + Math.random().toString(36).substr(2, 5)); }
    ;

block_exit
    : /* vazio */ { resetScope(); }
    ;

primary_expression
    : INT_LIT                     { $$ = createNode('int_lit', null, null, $1); }
    | F_LIT                       { $$ = createNode('float_lit', null, null, $1); }
    | C_LIT                       { $$ = createNode('char_lit', null, null, $1); }
    | STR_LIT                     { $$ = createNode('string_lit', null, null, $1); }
    | IDF                         { $$ = createNode('id', null, null, $1); }
    | IDF '[' expression ']'      { $$ = createNode('array_access', null, null, { id: $1, index: $3 }); }
    | IDF '.' IDF                 { $$ = createNode('struct_access', null, null, { id: $1, field: $3 }); }
    | IDF '(' argument_list ')'   { $$ = createNode('func_call', $1, null, $3); }
    | '(' expression ')'          { $$ = $2; }
    ;

unary_expression
    : primary_expression
    | AMP unary_expression        { $$ = createNode('address_of', $2, null, null); }
    | MULT unary_expression       { $$ = createNode('pointer_deref', $2, null, null); }
    | 'NOT' unary_expression      { $$ = createNode('un_op', $2, null, '!'); }
    | '(' type ')' unary_expression   %prec CAST { $$ = createNode('cast', $4, null, $2); }
    | SIZEOF '(' type ')'   { $$ = createNode('sizeof_type', null, null, $3); }
    | SIZEOF '(' expression ')' { $$ = createNode('sizeof_expr', null, null, $3);}
    ;

cast_expression
    : unary_expression
    | '(' type ')' cast_expression  %prec CAST { $$ = createNode('cast', $4, null, $2); }
    ;

expression
    : cast_expression
    | expression SUM expression       { $$ = createNode('bin_op', $1, $3, '+'); }
    | expression SUB expression       { $$ = createNode('bin_op', $1, $3, '-'); }
    | expression MULT expression      { $$ = createNode('bin_op', $1, $3, '*'); }
    | expression DIV expression       { $$ = createNode('bin_op', $1, $3, '/'); }
    | expression RDIV expression      { $$ = createNode('bin_op', $1, $3, '%'); }
    | expression '<' expression       { $$ = createNode('bin_op', $1, $3, '<'); }
    | expression '>' expression       { $$ = createNode('bin_op', $1, $3, '>'); }
    | expression 'EQ' expression      { $$ = createNode('bin_op', $1, $3, '=='); }
    | expression 'NE' expression      { $$ = createNode('bin_op', $1, $3, '!='); }
    | expression 'LE' expression      { $$ = createNode('bin_op', $1, $3, '<='); }
    | expression 'GE' expression      { $$ = createNode('bin_op', $1, $3, '>='); }
    | expression 'AND' expression     { $$ = createNode('bin_op', $1, $3, '&&'); }
    | expression 'OR' expression      { $$ = createNode('bin_op', $1, $3, '||'); }
    | expression AMP expression       { $$ = createNode('bin_op', $1, $3, '&'); }
    | expression '|' expression       { $$ = createNode('bin_op', $1, $3, '|'); }
    ;

values
    : values ',' expression
    | expression
    ; 

%%

