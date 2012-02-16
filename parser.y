%{
#include "ast.h"
#include <cstdio>
#include <cstdarg>
#include "symtable.h"
#include <stdio.h>
extern int yylex (void);
//void yyerror (char const *a){printf("ERROR: %s\n",a);};

void yyerror(char const *s, ...);

NBlock *ProgramAST;
int flagerror;
int flagfdecl=1;
Symtable Table;
%}

/* Ways to access data */

%union{
	Node *node;
	NBlock	*block;
	NExpression *expr;
	NStatement *stmt;
	NIdentifier	*ident;
	NLRExpression *lrexpr;
	NVariableDeclaration *var_decl;
	NArrayDeclaration *arr_decl;
	NArrayAccess *arr_access;
	NRegisterDeclaration *reg_decl;
	NUnionDeclaration *union_decl;
	std::vector<NVariableDeclaration*> *varvec;
	std::vector<NExpression*> *exprvec;
	std::string *string;
	int token;
	long long integer;
	double floating;
	char Char;
    void * error;

}

/* Terminal Symbols */

%token  <error> error
%token  <string> STR
%token	<integer> INT
%token	<floating> FLOAT
/*%token	<token> '=' '(' ')' '{' '}' ',' '.' '!' '<' '>' '%'
%token	<token> '+' '-' '/' '*'*/
%token 	<token> IF THEN ELSE FROM TO IN NEXT STOP
%token	<token>	CHAR UNION FUN TRUE FALSE
%token 	<token> REGISTER DO WHILE RETURN FOR 
%token	<string> ID

/* Type of node our nonterminal represent */
%type	<expr>	expr fun_call 
%type 	<lrexpr>	lrexpr
%type	<ident>	ident
%type	<varvec> fun_decl_args var_decls fun_decl_args_list
%type	<exprvec>	fun_call_args fun_call_args_lst /*array_elem*/
%type	<block>	program stmts block decls 
%type	<stmt>	stmt var_decl fun_decl reg_decl ctrl_for
%type	<stmt>	union_decl ctrl_while ctrl_if var_asgn
/*%type	<token>	comparison*/

/* Matematical operators precedence */
%nonassoc <token>	EQ NEQ GEQ LEQ '<' '>'	
%left	<token>	'+' '-' AND OR
%left	<token> '*' '/'
%left 	<token> NEG
%left	<token> ACCESS

%locations

%start program
%%
program 	: decls {ProgramAST = $1;}
			;

decls		: decl	{$$ = new NBlock();
                      $$->statements.push_back($<stmt>1);
                        flagfdecl=0;}
			| decls decl {$$->statements.push_back($<stmt>2);}
            | error decl { fprintf(stderr, 
                                    "Error in declaration, l%d,c%d-l%d,c%d\n",
                                    @1.first_line, @1.first_column,
                                    @1.last_line, @1.last_column);
                            if(flagfdecl)
                            $$ = new NBlock();}
			;

decl		: var_decl '.'
			| reg_decl 
			| union_decl 
			| fun_decl
            | error '.' {fprintf(stderr, 
                                    "Error in declaration, l%d,c%d-l%d,c%d\n",
                                    @1.first_line, @1.first_column,
                                    @1.last_line, @1.last_column);}

			;

var_decl	: ident ident {$$ = new NVariableDeclaration(*$1,*$2);
                            TElement * t;
                            cout << $1->name << endl;
                            cout << $2->name << endl;
                            if((t=Table.lookupType($1->name))!=NULL){
                                Table.insert($2->name,new TVar(*((TType *)t)));
                             }
                          }
			| ident ident '=' expr {$$ = new NVariableDeclaration(*$1,*$2,$4);
                                    TElement * t;
                            cout << $1->name << "ini" << endl;
                            cout << $2->name << "ini" << endl;
                                    if((t=Table.lookupType($1->name))!=NULL){
                                        Table.insert($2->name,
                                        new TVar(*((TType *)t)));}}
            /*| ident error {}*/
			;

fun_decl	: ident FUN ident fun_decl_args block {$$ = new NFunctionDeclaration(*$1,*$3,*$4,*$5);}
			;

union_decl	: UNION ident '{' var_decls '}' {$$ = new NUnionDeclaration(*$2,*$4);}
            | UNION ident '{' error '}' {fprintf(stderr, 
                                    "Error in union member declarations, l%d,c%d-l%d,c%d\n",
                                    @4.first_line, @4.first_column,
                                    @4.last_line, @4.last_column);}

			;

reg_decl	: REGISTER ident '{' var_decls '}' {$$ = new NRegisterDeclaration(*$2,*$4);}
            | REGISTER ident '{' error '}' {fprintf(stderr, 
                                    "Error in register member declarations, l%d,c%d-l%d,c%d\n",
                                    @4.first_line, @4.first_column,
                                    @4.last_line, @4.last_column);}
			;

var_decls	: var_decl {$$ = new VariableList();$$->push_back($<var_decl>1);}
			| var_decls ',' var_decl {$$->push_back($<var_decl>3);}
            | var_decls error var_decl {fprintf(stderr, 
                                    "Missing ' character, l%d,c%d-l%d,c%d\n",
                                    @2.first_line, @2.first_column,
                                    @2.last_line, @2.last_column);
                                    $$->push_back($<var_decl>3);}
			;

fun_decl_args: '(' ')' {$$ = new VariableList();}
			| '(' fun_decl_args_list ')' {$$ = $2;}
            | '(' fun_decl_args_list error {fprintf(stderr, 
                                    "Missing ) character, l%d,c%d-l%d,c%d\n",
                                    @3.first_line, @3.first_column,
                                    @3.last_line, @3.last_column);
                                    $$= $2;}
			;

fun_decl_args_list: var_decl {$$ = new VariableList();$$->push_back($<var_decl>1);}
			| fun_decl_args_list ',' var_decl {$$->push_back($<var_decl>3);}
            | fun_decl_args_list error var_decl {fprintf(stderr, 
                                    "Missing ' character, l%d,c%d-l%d,c%d\n",
                                    @2.first_line, @2.first_column,
                                    @2.last_line, @2.last_column);
                                    $$->push_back($<var_decl>3);
                                    yyerrok;}
			;

ident		: ID {$$ = new NIdentifier(*$1);}


expr		: lrexpr{$$ = $<expr>1;} 
			| INT	{$$ = new NInteger($1);}	
			| FLOAT	{$$ = new NDouble($1);}
			| STR 	{$$ = new NString(*$1);}
			| CHAR	{$$ = new NChar($1);}	
			| TRUE	{$$=new NBool(true);}
			| FALSE	{$$=new NBool(false);}
			| fun_call  
			| expr '+' expr {$$=new NBinaryOperator(*$1,$2,*$3);}
			| expr '-' expr {$$=new NBinaryOperator(*$1,$2,*$3);}
			| expr '/' expr {$$=new NBinaryOperator(*$1,$2,*$3);}
			| expr '*' expr {$$=new NBinaryOperator(*$1,$2,*$3);}
			| expr AND expr {$$=new NBinaryOperator(*$1,$2,*$3);}
			| expr OR expr	{$$=new NBinaryOperator(*$1,$2,*$3);}
			| expr '<' expr {$$=new NBinaryOperator(*$1,$2,*$3);}
			| expr '>' expr {$$=new NBinaryOperator(*$1,$2,*$3);}
			| expr GEQ expr {$$=new NBinaryOperator(*$1,$2,*$3);}
			| expr LEQ expr {$$=new NBinaryOperator(*$1,$2,*$3);}
			| expr NEQ expr {$$=new NBinaryOperator(*$1,$2,*$3);}
			| expr EQ expr {$$=new NBinaryOperator(*$1,$2,*$3);}
			| '-' expr %prec NEG {$$=new NUnaryOperator($1,*$2);}
			| '(' expr ')'	{$$=$2;}
            /*| error ')' {@$.first_column = @1.first_column;
                            @$.first_line = @1.first_line;
                            @$.last_column = @2.last_column;
                            @$.last_line = @2.last_line;
                            fprintf(stderr, "Error detected, l%d,c%d-l%d,c%d",
                                        @1.first_line, @1.first_column,
                                        @2.last_line, @2.last_column);
                            }*/
			;

lrexpr		: ident	{$$=new NIdentifier(*$1);}
			| lrexpr '[' expr ']' {$$=new NArrayAccess(*$1,*$3);}
			| lrexpr ACCESS ident 	{$$=new NStructAccess(*$1,*$3);}
            /*| error ']' {}*/
			; 

fun_call_args : '(' ')' {$$= new ExpressionList();}
			| '(' fun_call_args_lst ')' {$$=$2;}
			;	
	
fun_call_args_lst : expr {$$=new ExpressionList();$$->push_back($1);}
			| fun_call_args_lst ',' expr {$$->push_back($3);}
            | fun_call_args_lst error expr {}
            ;

block		: beg_block end_block {$$ = new NBlock();}
			| beg_block stmts end_block {$$ =$2;}
			;

beg_block	: '{' {Table.begScope();}
			;

end_block	: '}' {Table.endScope();}
			;

stmts		: stmt  {$$ = new NBlock();$$->statements.push_back($1);}
			| stmts stmt {$$->statements.push_back($2);}
            | error stmt { fprintf(stderr, 
                                    "Error in previous stament, l%d,c%d-l%d,c%d\n",
                                    @2.first_line, @2.first_column,
                                    @2.last_line, @2.last_column);
                                    $$->statements.push_back($2);}
			;

stmt		: ctrl_if 	
			| ctrl_while 
			| ctrl_for	{}
			| block 	{$$=$<stmt>1;}
			| var_decl '.' 
			| var_asgn '.' 
			| fun_call '.' {$$ = new NExpressionStatement(*$1);}
			| RETURN '.' {$$ = new NReturn();}
			| RETURN expr '.' {$$ = new NReturn($2);}
			| STOP '.' {$$ = new NStop();}
			| NEXT '.' {$$ = new NNext();}
            | error '.' {}
			;

fun_call	: ident fun_call_args {$$ = new NFunctionCall(*$1,*$2);}

ctrl_if		: IF expr THEN block {$$ = new NIf(*$2,*$4);}
			| IF expr THEN block ELSE block {$$ = new NIf(*$2,*$4,$6);}
			| IF expr THEN block ELSE ctrl_if {$$ = new NIf(*$2,*$4,$6);}
			;

ctrl_while	: WHILE expr DO block {$$ = new NWhileDo($2,*$4);}
			| DO block WHILE expr '.' {$$ = new NDoWhile($4,*$2);}
			;

ctrl_for	: FOR ident FROM expr TO expr block {$$ = new NFor(*$2,$4,$6,*$7);}
			| FOR ident IN ident block {$$ = new NFor(*$2,$4,*$5);}
			;

var_asgn	: lrexpr '=' expr {$$ = new NAssignment($1,$3); }
            | error '=' {}
			;

%%

/* in code section at the end of the parser */
void yyerror(char const *s, ...){
  va_list ap;
  va_start(ap, s);

  if(yylloc.first_line)
    fprintf(stderr, "\n%d.%d-%d.%d: error: ", yylloc.first_line, yylloc.first_column,
        yylloc.last_line, yylloc.last_column);
  vfprintf(stderr, s, ap);
  fprintf(stderr, "\n");

}

void lyyerror(YYLTYPE t, char const *s, ...){
  va_list ap;
  va_start(ap, s);

  if(t.first_line)
    fprintf(stderr, "\n%d.%d-%d.%d: error: ", t.first_line, t.first_column,
        t.last_line, t.last_column);
  vfprintf(stderr, s, ap);
  fprintf(stderr, "\n");
}

/*void yyerror(char *s){
    printf("%d: %s at %s\n", yylineno, s, yytext);
}*/

