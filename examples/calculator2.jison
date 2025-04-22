%lex
%%

"int"              return 'INT';
"float"            return 'FLOAT';
"if"               return 'IF';
"else"             return 'ELSE';
"while"            return 'WHILE';
"do"               return 'DO';
"for"              return 'FOR';
"return"           return 'RETURN';

"="                return '=';
"=="               return '==';
"!="               return '!=';
"<="               return '<=';
">="               return '>=';
"<"                return '<';
">"                return '>';
"&&"               return '&&';
"\|\|"             return '||';
"\+\+"             return '++';
"--"               return '--';
"\+"               return '+';
"-"                return '-';
"\*"               return '*';
"/"                return '/';
"%"                return '%';
"\["               return '[';
"\]"               return ']';
"\{"               return '{';
"\}"               return '}';
"\("               return '(';
"\)"               return ')';
";"                return ';';
","                return ',';

[0-9]+\.[0-9]+     return 'FLOAT_LITERAL';
[0-9]+             return 'INT_LITERAL';

"//".*             return 'COMMENT';
"/\\*"[^*]*"\\*/"  return 'COMMENT_BLOCK';

[a-zA-Z_][a-zA-Z0-9_]* return 'ID';

[\t\n\r ]+         /* ignore whitespace */;
.                  return 'INVALID';
/lex

%start program

%token INT FLOAT IF ELSE WHILE DO FOR RETURN
%token ID INT_LITERAL FLOAT_LITERAL
%token '=' '==' '!=' '<=' '>=' '<' '>' '&&' '||' '++' '--' '+' '-' '*' '/' '%' '[' ']' '{' '}' '(' ')' ';' ','

%left '+' '-'
%left '*' '/' '%'
%left '&&' '||'
%left '==' '!='
%left '<' '>' '<=' '>='
%right '='
%right '++' '--'

%%

program
    : block
    ;

block
    : '{' statements '}'
    ;

statements
    : /* vazio */
    | statement statements
    ;

statement
    : declaration ';'
    | assignment ';'
    | expression ';'
    | if_statement
    | for_loop
    | while_loop
    | do_while_loop
    | block
    ;

declaration
    : type varlist
    ;

varlist
    : ID
    | ID '=' expression
    | ID '[' INT_LITERAL ']'
    | ID '[' INT_LITERAL ']' '=' '{' elements '}'
    | varlist ',' ID
    ;

elements
    : expression
    | expression ',' elements
    ;

type
    : INT
    | FLOAT
    ;

assignment
    : ID '=' expression
    | ID '+=' expression
    | ID '-=' expression
    ;

expression
    : expression '+' expression        { $$ = $1 + $3; }
    | expression '-' expression        { $$ = $1 - $3; }
    | expression '*' expression        { $$ = $1 * $3; }
    | expression '/' expression        { $$ = $1 / $3; }
    | expression '%' expression        { $$ = $1 % $3; }
    | expression '&&' expression       { $$ = $1 && $3; }
    | expression '||' expression       { $$ = $1 || $3; }
    | expression '==' expression       { $$ = $1 == $3; }
    | expression '!=' expression       { $$ = $1 != $3; }
    | expression '<' expression        { $$ = $1 < $3; }
    | expression '<=' expression       { $$ = $1 <= $3; }
    | expression '>' expression        { $$ = $1 > $3; }
    | expression '>=' expression       { $$ = $1 >= $3; }
    | '(' expression ')'               { $$ = $2; }
    | ID                               { $$ = $1; }
    | INT_LITERAL                      { $$ = parseInt($1, 10); }
    | FLOAT_LITERAL                    { $$ = parseFloat($1); }
    ;


if_statement
    : IF '(' expression ')' statement no_else      // 'if' sem 'else'
    | IF '(' expression ')' statement ELSE statement  // 'if' com 'else'
    ;

no_else
    : statement
    ;

for_loop
    : FOR '(' assignment ';' expression ';' assignment ')' statement
    ;

while_loop
    : WHILE '(' expression ')' statement
    ;

do_while_loop
    : DO statement WHILE '(' expression ')' ';'
    ;
