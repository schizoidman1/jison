/* description: Parses and executes mathematical expressions. */

/* lexical grammar */
%lex
%%

\s+                     /* ignora espaços em branco */
"int"                   return 'INT';       // Palavra-chave int
"float"                 return 'FLOAT';     // Palavra-chave float
"char"                  return 'CHAR';      // Tipo de caractere
[0-9]+                  return 'NUMBER';    // Números inteiros
[0-9]+\.[0-9]+          return 'NUMBER';    // Números decimais
[a-zA-Z_][a-zA-Z0-9_]*  return 'ID';        // Identificadores (nomes de variáveis)
"//"[^\n]*              return 'COM';
"/*"[^\n]*'*/'          return 'COM';
"if"                    return 'IF';        // Palavra-chave if
"else"                  return 'ELSE';      // Palavra-chave else
"while"                 return 'WHILE';     // Palavra-chave while
"for"                   return 'FOR';       // Palavra-chave for
"return"                return 'RETURN';    // Palavra-chave return
"{"                     return '{';         // Chave de abertura
"}"                     return '}';         // Chave de fechamento
"("                     return '(';         // Parêntese de abertura
")"                     return ')';         // Parêntese de fechamento
";"                     return ';';         // Ponto e vírgula
"="                     return '=';         // Operador de atribuição
"+"                     return '+';         // Operador de soma
"-"                     return '-';         // Operador de subtração
"*"                     return '*';         // Operador de multiplicação
"/"                     return '/';         // Operador de divisão
"%"                     return '%';
"=="                    return 'EQ';        // Operador de igualdade
"!="                    return 'NEQ';       // Operador de desigualdade
"<"                     return 'LT';        // Menor que
">"                     return 'GT';        // Maior que
"\+="                   return 'PLUSEQ';     // +=
"-="                    return 'MINUSEQ';    // -=
"\*="                   return 'MULEQ';      // *=
"/="                    return 'DIVEQ';      // /=
"&&"                    return 'AND';       // Operador lógico AND
"||"                    return 'OR';        // Operador lógico OR
"!"                     return 'NOT';       // Operador lógico NOT
"++"                    return 'INCREMENT'; // Operador de incremento
"--"                    return 'DECREMENT'; // Operador de decremento
"["                     return '[';
"]"                     return ']';
","                     return ',';
<<EOF>>                 return 'EOF';       // Fim de arquivo
.                       return 'INVALID';   // Qualquer outro caractere não válido

%%

/lex

/* operator associations and precedence */

%left '+' '-'
%left '*' '/' '%'
%left EQ NEQ LT GT
%left AND OR
%right '='
%left UMINUS
%right NOT
%right INCREMENT DECREMENT


%start program

%%

program
    : block_statement EOF
    ;

block_statement
    : '{' statement_list '}'
        { console.log("Bloco de código encontrado"); }
    ;

statement_list
    : statement_list statement
    | statement
    ;

statement
    : expression_statement
    | declaration_statement
    | if_statement
    | while_statement
    | for_statement
    | do_while_statement
    | block_statement
    | return_statement
    ;

declaration_statement
    : type var_decl_list ';'
      { console.log("Declaração(s) encontrada(s): " + $2); }
    ;

var_decl_list
    : var_decl_list ',' var_decl
    | var_decl
    ;

var_decl
    : ID
    | ID '=' expression
    | ID '[' NUMBER ']'           // arr sem init
    | ID '[' NUMBER ']' '=' array_initializer
    ;

array_initializer
    : '{' init_list '}'
    ;

init_list
    : expression
    | init_list ',' expression
    ;

/* if, while, for, do-while */
if_statement
    : 'if' '(' expression ')' statement
      | 'if' '(' expression ')' statement 'else' statement
    ;

while_statement
    : 'while' '(' expression ')' statement
    ;

do_while_statement
    : 'do' statement 'while' '(' expression ')' ';'
    ;

for_statement
    : 'for' '(' declaration_opt expression_statement expression ')' statement
    | 'for' '(' expression_statement expression_statement expression ')' statement
    ;

declaration_opt
    : declaration_statement
    | /* vazio */

/* return */
return_statement
    : 'return' expression ';'
    ;

/* expressions */
expression_statement
    : expression ';'
    ;

"\+="                   return 'PLUSEQ';     // +=
"-="                    return 'MINUSEQ';    // -=
"\*="                   return 'MULEQ';      // *=
"/="                    return 'DIVEQ';      // /=

expression
    : expression '+' expression
    | expression '-' expression
    | expression '*' expression
    | expression '/' expression
    | expression '%' expression
    | expression 'EQ' expression
    | expression 'NEQ' expression
    | expression 'LT' expression
    | expression 'GT' expression
    | expression 'LE' expression
    | expression 'GE' expression
    | expression 'PLUSEQ' expression
    | expression 'MINUSEQ' expression
    | expression 'MULEQ' expression
    | expression 'DIVEQ' expression
    | expression 'AND' expression
    | expression 'OR' expression
    | ID '=' expression
    | ID 'PLUSEQ' expression    /* += */
    | ID 'MINUSEQ' expression   /* -= */
    | '(' expression ')'
    | ID '[' expression ']'     /* array[i] */
    | ID
    | NUMBER
    | '!' expression
    ;

declaration
    : type ID '(' parameter_list ')' '{' statement_list '}'
      { console.log("Função declarada: " + $2 + " com parâmetros " + $4); }
    ;

type
    : INT    { $$ = 'int'; }
    | FLOAT  { $$ = 'float'; }
    | CHAR   { $$ = 'char'; }
    ;

parameter_list
    : parameter_list ',' type ID
        { /* ... */ }
    | type ID
        { /* ... */ }
    | /* vazio */
    ;
%%

