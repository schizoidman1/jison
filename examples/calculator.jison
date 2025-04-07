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
"&&"                    return 'AND';       // Operador lógico AND
"||"                    return 'OR';        // Operador lógico OR
"!"                     return 'NOT';       // Operador lógico NOT
"++"                    return 'INCREMENT'; // Operador de incremento
"--"                    return 'DECREMENT'; // Operador de decremento
"["                     return '[';
"]"                     return ']';
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
    : declaration_list EOF
    ;

declaration_list
    : declaration_list declaration
    | declaration
    ;

declaration
    : type ID ';'                                   { console.log("Declaração de variável: " + $1 + " " + $2); }
    | type ID '=' expression ';'                     { console.log("Declaração com atribuição: " + $1 + " " + $2 + " = " + $4); }
    | type ID '(' parameter_list ')' '{' statement_list '}'
        { console.log("Função declarada: " + $2 + " com parâmetros " + $4); }
    ;

type
    : INT    { $$ = 'int'; }
    | FLOAT  { $$ = 'float'; }
    | CHAR   { $$ = 'char'; }
    ;

parameter_list
    : parameter_list ',' type ID
        { $$ = $1.concat($3); }
    | type ID
        { $$ = [$2]; }
    | /* vazio */
        { $$ = []; }
    ;

statement_list
    : statement_list statement
    | statement
    ;

statement
    : expression_statement
    | if_statement
    | while_statement
    | for_statement
    | return_statement
    | block_statement
    ;

expression_statement
    : expression ';'                               { console.log("Expressão: " + $1); }
    ;

if_statement
    : 'if' '(' expression ')' statement
        { console.log("IF encontrado"); }
    | 'if' '(' expression ')' statement 'else' statement
        { console.log("IF com ELSE encontrado"); }
    ;

while_statement
    : 'while' '(' expression ')' statement
        { console.log("While encontrado"); }
    ;

for_statement
    : FOR '(' declaration expression_statement expression ')' statement
        { console.log("For com declaração de variável encontrado") }
    ;

return_statement
    : 'return' expression ';'                       { console.log("Return encontrado: " + $2); }
    ;

block_statement
    : '{' statement_list '}'
        { console.log("Bloco de código encontrado"); }
    ;

expression
    : expression '+' expression                        { $$ = $1 + $3; }
    | expression '-' expression                        { $$ = $1 - $3; }
    | expression '*' expression                        { $$ = $1 * $3; }
    | expression '/' expression                        { $$ = $1 / $3; }
    | '(' expression ')'                               { $$ = $2; }
    | ID '=' expression                                { $$ = $1 + " = " + $3; }
    | NUMBER                                           { $$ = parseInt(yytext, 10); }
    | '!' expression                                   { $$ = !$2; }
    | ID                                              { $$ = $1; }
    | expression '&&' expression                       { $$ = $1 && $3; }  // Operador lógico AND
    | expression '||' expression                       { $$ = $1 || $3; }  // Operador lógico OR
    ;
