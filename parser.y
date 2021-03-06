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
bool flagerror=false;
int flagfdecl=0;
Symtable Table;
%}

/* Ways to access data */

%union{
	Node *node;
	NBlock *block;
	NExpression *expr;
	NStatement *stmt;
	NIdentifier	*ident;
	NLRExpression *lrexpr;
	NVariableDeclaration *var_decl;
	NArrayDeclaration *arr_decl;
	NFunctionDeclaration *fun_decl;
	NArrayAccess *arr_access;
	NRegisterDeclaration *reg_decl;
	NUnionDeclaration *union_decl;
    NArray *cons_arr;
	std::vector<NVarrayDeclaration*> *varvec;
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
%token	<token>	CHAR UNION ARRAY TRUE FALSE STRIN
%token 	<token> REGISTER DO WHILE RETURN FOR STEP 
%token	<string> ID

/* Type of node our nonterminal represent */
%type	<expr>	expr fun_call
%type 	<lrexpr> lrexpr
%type	<ident>	ident
%type	<varvec> fun_decl_args var_decls fun_decl_args_list
%type	<exprvec> fun_call_args expr_lst
%type	<block>	program stmts block decls 
%type 	<fun_decl> fun_firm
%type   <cons_arr> cons_arr arr_lst
%type 	<reg_decl> reg_decl
%type	<union_decl> union_decl
%type   <arr_decl> arr_decl str_decl
%type	<stmt>	stmt var_decl fun_decl ctrl_for
%type	<stmt>	ctrl_while ctrl_if var_asgn
/*%type	<token>	comparison*/

/* Matematical operators precedence */
%nonassoc <token>	EQ NEQ GEQ LEQ '<' '>'	
%left	<token>	'+' '-' AND OR
%left	<token> '*' '/'
%left 	<token> NEG NOT
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
                            flagerror=1;
                            if(flagfdecl)
                            $$ = new NBlock();}
			;

decl		: varr_decl '.'
			| reg_decl 
			| union_decl 
			| fun_decl
            | error '.' {fprintf(stderr, 
                                    "Error in declaration, l%d,c%d-l%d,c%d\n",
                                    @1.first_line, @1.first_column,
                                    @1.last_line, @1.last_column);
                         flagerror=1;
                        }

			;

varr_decl	: var_decl
			| arr_decl
            | str_decl
			;

var_decl	: ident ident {
                  TElement * t;
                  $$ = new NVariableDeclaration(*$1,*$2);

                  if((t=Table.lookupScope($2->name))!=NULL){
                      flagerror = 1;
                      cerr<<"Variable `"<< $2->name<< "` was declare before: l"
                          <<@2.first_line<<",c"<<@2.first_column<<"-l"<<
                          @2.first_line<<",c"<<@2.first_column<<endl;
                  }

                  if((t=Table.lookupType($1->name))!=NULL){
#ifdef DEBUG
					  cerr<<" inserting variable "<< $2->name<<" as "<<$1->name<<endl;
#endif
                      Table.insert($2->name,new TVar($2->name,*((TType *)t)));
                  }else{
					  flagerror=1;
					  cerr<<"Error "<<$1->name<<" does not name a type"<<endl;
				  }
    
                          }
            | ident ident '=' expr {$$ = new NVariableDeclaration(*$1,*$2,$4);
                TElement * t;

                 if((t=Table.lookupScope($2->name))!=NULL){
                    flagerror = 1;
                    cerr<<"Variable `"<< $2->name<< "` was declare before: l"
                        <<@2.first_line<<",c"<<@2.first_column<<"-l"<<
                        @2.first_line<<",c"<<@2.first_column<<endl;
                }

                if((t=Table.lookupType($1->name))!=NULL){
                    Table.insert($2->name,
                            new TVar($1->name,*((TType *)t)));
                }else{
			            flagerror=1;
			            cerr<<"Error "<<$1->name<<" does not name a type"<<endl;
		        }

                                               }
            /*| ident error {}*/
			;

fun_decl	: fun_firm block {$1->block = $2;$$ = $1;}
            /*FIRMAS DE FUNCIONES PARA EL PROX TRIMESTRE | fun_firm {$$=$1;}*/
			;

fun_firm	: ident ident fun_decl_args {
                  $$ = new NFunctionDeclaration(*$1,*$2,*$3);
                  if($$->addSymtable(Table)==2){
                      flagerror=1;
                      cerr<<"Function `"<< $$->id.name<< "` was declare before: l"
                          <<@2.first_line<<",c"<<@2.first_column<<"-l"<<
                          @2.first_line<<",c"<<@2.first_column<<endl;
                  }} 

str_decl    : STRIN cons_arr ident {
                  $$ = new NArrayDeclaration(*$3,*(new NIdentifier(*( new std::string("char")))),*$2);
                  if($$->addSymtable(Table)==1)
                      cerr<<"Array `"<< $$->id.name<< "`. l"
                          <<@3.first_line<<",c"<<@3.first_column<<"-l"<<
                          @3.first_line<<",c"<<@3.first_column<<endl;
                  flagerror=1;
                                    }
| STRIN cons_arr ident '=' STR {$$ = new NArrayDeclaration(*$3,*(new NIdentifier(*(new std::string("char")))),*$2,new NArray(*$5));
                        if($$->addSymtable(Table)==1)
                            cerr<<"Array `"<< $$->id.name<< "`. l"
                                <<@3.first_line<<",c"<<@3.first_column<<"-l"<<
                                @3.first_line<<",c"<<@3.first_column<<endl;
                            flagerror=1;

                                            }
            ;

arr_decl    : ARRAY cons_arr ident ident {$$ = new NArrayDeclaration(*$4,*$3,*$2);
                  if($$->addSymtable(Table)==1)
                      cerr<<"Array `"<< $$->id.name<< "`: l"
                          <<@4.first_line<<",c"<<@4.first_column<<"-l"<<
                          @4.first_line<<",c"<<@4.first_column<<endl;
                  flagerror=1;
                                    }
| ARRAY cons_arr ident ident '=' arr_lst {$$ = new NArrayDeclaration(*$4,*$3,*$2,$6);
                    if($$->addSymtable(Table)==1)
                        cerr<<"Array `"<< $$->id.name<< "`: l"
                            <<@4.first_line<<",c"<<@4.first_column<<"-l"<<
                            @4.first_line<<",c"<<@4.first_column<<endl;
                    flagerror=1;

                                                        }

union_decl	: UNION ident beg_block var_decls end_block {$$ = new NUnionDeclaration(*$2,*$4);}
            | UNION ident beg_block error end_block {fprintf(stderr, 
                                    "Error in union member declarations, l%d,c%d-l%d,c%d\n",
                                    @4.first_line, @4.first_column,
                                    @4.last_line, @4.last_column);}

			;

reg_decl	: REGISTER ident beg_block var_decls '}' {$$ = new NRegisterDeclaration(*$2,*$4);$$->addToSymtable(Table);Table.endScope();}
            | REGISTER ident beg_block error end_block {fprintf(stderr, 
                                    "Error in register member declarations, l%d,c%d-l%d,c%d\n",
                                    @4.first_line, @4.first_column,
                                    @4.last_line, @4.last_column);
                                    flagerror=1;
                                    }
			;

var_decls	: var_decl {$$ = new VariableList();$$->push_back($<var_decl>1);}
			| var_decls ',' var_decl {$$->push_back($<var_decl>3);}
            | var_decls error var_decl {fprintf(stderr, 
                                    "Missing ' character, l%d,c%d-l%d,c%d\n",
                                    @2.first_line, @2.first_column,
                                    @2.last_line, @2.last_column);
                                    $$->push_back($<var_decl>3);
                                    flagerror=1;
                                    }
			;

fun_decl_args: fun_scope ')' {$$ = new VariableList();}
			| fun_scope fun_decl_args_list ')' {$$ = $2;}
            | fun_scope fun_decl_args_list error {fprintf(stderr, 
                                    "Missing ) character, l%d,c%d-l%d,c%d\n",
                                    @3.first_line, @3.first_column,
                                    @3.last_line, @3.last_column);
                                    $$= $2;}
			;

fun_scope:  '(' {Table.begScope();}

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
			| TRUE	{$$ = new NBool(true);}
			| FALSE	{$$ = new NBool(false);}
			| fun_call  
			| expr '+' expr {$$=new NBinaryOperator($1,"+",$3);}
			| expr '-' expr {$$=new NBinaryOperator($1,"-",$3);}
			| expr '/' expr {$$=new NBinaryOperator($1,"/",$3);}
			| expr '*' expr {$$=new NBinaryOperator($1,"*",$3);}
			| expr AND expr {$$=new NBinaryOperator($1,"and",$3);}
			| expr OR expr	{$$=new NBinaryOperator($1,"or",$3);}
			| expr '<' expr {$$=new NBinaryOperator($1,"<",$3);}
			| expr '>' expr {$$=new NBinaryOperator($1,">",$3);}
			| expr GEQ expr {$$=new NBinaryOperator($1,">=",$3);}
			| expr LEQ expr {$$=new NBinaryOperator($1,"<=",$3);}
			| expr NEQ expr {$$=new NBinaryOperator($1,"!=",$3);}
			| expr EQ expr {$$=new NBinaryOperator($1,"==",$3);}
			| '-' expr %prec NEG {$$=new NUnaryOperator("-",$2);}
			| '!' expr %prec NOT {$$=new NUnaryOperator("not",$2);}
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

lrexpr		: ident	{ if(Table.lookup($1->name)!=NULL){
							$$=new NIdentifier(*$1);
						}else{
							fprintf(stderr,"var %s is not declared.\n",$1->name.c_str());
                            flagerror=1;
						}
					}

			| lrexpr '[' expr ']' {$$=new NArrayAccess($1,$3);}
			| lrexpr ACCESS ident 	{$$=new NStructAccess($1,*$3);}
            /*| error ']' {}*/
			; 

fun_call_args : '(' ')' {$$= new ExpressionList();}
			| '(' expr_lst ')' {$$=$2;}
			;	

cons_arr    : '[' expr_lst ']' {$$ = new NArray(*$2);}
            ;

arr_lst     : cons_arr {$$ = $1;}
            | '['arr_lst ',' cons_arr']' {$$ = new NArray();
                                            $$->add($4);
                                            $$->add($2);}
            | arr_lst error cons_arr {}
            ;
	
expr_lst    : expr {$$=new ExpressionList();$$->push_back($1);}
			| expr_lst ',' expr {$$->push_back($3);}
            | expr_lst error expr {}
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
                                    $$->statements.push_back($2);
                            flagerror=1;
                            }
			;

stmt		: ctrl_if 	
			| ctrl_while 
			| ctrl_for	
			| block 	{$$=$<stmt>1;}
			| var_asgn '.'
			| varr_decl '.' {$$=$<stmt>1;}
			| fun_call '.' {$$ = new NExpressionStatement($1);}
			| RETURN '.' {$$ = new NReturn();}
			| RETURN expr '.' {$$ = new NReturn($2);}
			| STOP '.' {$$ = new NStop();}
			| NEXT '.' {$$ = new NNext();}
            | error '.' {}
			;

fun_call	: ident fun_call_args {$$ = new NFunctionCall(*$1,*$2);}

ctrl_if		: IF expr THEN block {$$ = new NIf($2,*$4);}
			| IF expr THEN block ELSE block {$$ = new NIf($2,*$4,$6);}
			| IF expr THEN block ELSE ctrl_if {$$ = new NIf($2,*$4,$6);}
			;

ctrl_while	: WHILE expr DO block {$$ = new NWhileDo($2,*$4);}
			| DO block WHILE expr '.' {$$ = new NDoWhile($4,*$2);}
			;

ctrl_for	: FOR ident FROM expr TO expr block {$$ = new NFor(*$2,$4,$6,*$7);}
			| FOR ident FROM expr TO expr STEP expr block{$$ = new NFor(*$2,$4,$6,*$9,$8);}
			| FOR ident IN ident block {$$ = new NFor(*$2,$4,*$5);}
			| FOR ident IN cons_arr block {$$ = new NFor(*$2,$4,*$5);}
			;

var_asgn	: lrexpr '=' expr {$$ = new NAssignment($1,$3);}
            | error '=' {}
			;

%%

/* in code section at the end of the parser */
void yyerror(char const *s, ...){
  va_list ap;
  va_start(ap, s);

  if(yylloc.first_line)
    fprintf(stderr, "\nSyntax error in line %d", yylloc.first_line, yylloc.first_column,
        yylloc.last_line, yylloc.last_column);
  vfprintf(stderr, s, ap);
  fprintf(stderr, "\n");
  flagerror = 1;

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

