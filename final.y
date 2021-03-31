%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *message);
int load_id(char *id);

struct DATA {
	char sval[64];
	int ival;
} data[128];

int data_top = 0;
int t;
%}
%union {
	int ival;
	struct {
		int ival;
		int output;
	} eq;
	char str[64];
}

%token PRINT_NUM PRINT_BOOL
%token<ival> BOOL_VAL NUMBER
%token MOD
%token AND OR NOT
%token DEFINE FUN
%token<str> ID
%token IF

/*********************************************************/

%type<ival> start

%type<ival> program

%type<ival> stmt
%type<ival> print_stmt

%type<ival> exp

%type<ival> num_op 
%type<ival> plus minus multiply divide modulus
%type<ival> greater smaller equal
%type<ival> plus_exps multi_exps
%type<eq> equal_exps

%type<ival> logical_op
%type<ival> and_op or_op not_op
%type<ival> and_exps or_exps

%type<ival> def_stmt
%type<str> variable

%type<ival> fun_exp fun_ids fun_body fun_call
%type<ival> param /*last_exp*/ fun_name
%type<ival> ids params

%type<ival> if_exp test_exp then_exp else_exp

%%

start		: program {}
			;
program		: stmt program {}
			| stmt {}
			;
stmt		: exp {}
			| def_stmt {}
			| print_stmt {}
			;
print_stmt	: '(' PRINT_NUM exp ')' { printf("%d\n", $3); }
			| '(' PRINT_BOOL exp ')' {
				if($3) printf("#t\n");
				else printf("#f\n");
			}
			;
exp			: BOOL_VAL {}
			| NUMBER {}
			| variable { $$ = load_id($1); }
			| num_op {}
			| logical_op {}
			| fun_exp {}
			| fun_call {}
			| if_exp {}
			;
/*********************************************************/
num_op		: plus {}
			| minus {}
			| multiply {}
			| divide {}
			| modulus {}
			| greater {}
			| smaller {}
			| equal {}
			;
plus		: '(' '+' plus_exps ')' { $$ = $3; }
			;
plus_exps	: plus_exps exp { $$ = $1 + $2; }
			| exp exp { $$ = $1 + $2; }
			;
minus		: '(' '-' exp exp ')' { $$ = $3 - $4; }
			;
multiply	: '(' '*' multi_exps ')' { $$ = $3; }
			;
multi_exps	: multi_exps exp { $$ = $1 * $2; }
			| exp exp { $$ = $1 * $2; }
			;
divide		: '(' '/' exp exp ')' { $$ = $3 / $4; }
			;
modulus		: '(' MOD exp exp ')' { $$ = $3 % $4; }
			;
greater		: '(' '>' exp exp ')' {
				if($3 > $4) $$ = 1;
				else $$ = 0;
			}
			;
smaller		: '(' '<' exp exp ')' {
				if($3 < $4) $$ = 1;
				else $$ = 0;
			}
			;
equal		: '(' '=' equal_exps ')' { $$ = $3.output; }
			;
equal_exps	: equal_exps exp {
				$$.ival = $2;
				$$.output = ($1.output)&&($1.ival==$2);
			}
			| exp exp {
				$$.ival = $2;
				$$.output = $1==$2;
			}
			;
/*********************************************************/
logical_op	: and_op {}
			| or_op {}
			| not_op {}
			;
and_op		: '(' AND and_exps ')' { $$ = $3; }
			;
and_exps	: and_exps exp { $$ = $1 && $2; }
			| exp exp { $$ = $1 && $2; }
			;
or_op		: '(' OR or_exps ')' { $$ = $3; }
			;
or_exps		: or_exps exp { $$ = $1 || $2; }
			| exp exp { $$ = $1 || $2; }
			;
not_op		: '(' NOT exp ')' { $$ = ($3==0); }
			;
/*********************************************************/
def_stmt	: '(' DEFINE variable exp ')' {
				if(data_top<100) {
					sprintf(data[data_top].sval, "%s", $3);
					data[data_top].ival = $4;
					data_top++;
				}
			}
			;
variable	: ID { sprintf($$, "%s", $1); }
			;
/*********************************************************/
fun_exp		: '(' FUN fun_ids fun_body ')' {}
			;
fun_ids		: '(' ids ')' {}
			;
ids			: ids ID {}
			| {}
			;
fun_body	: exp {}
			;
fun_call	: '(' fun_exp params ')' {}
			| '(' fun_name params ')' {}
			;
params		: params param {}
			| {}
			;
param		: exp {}
			;
/*last_exp	: exp {}
			;*/
fun_name	: ID {}
			;
/*********************************************************/
if_exp		: '(' IF test_exp then_exp else_exp ')' {
				if($3) $$ = $4;
				else $$ = $5;
			}
			;
test_exp	: exp {}
			;
then_exp	: exp {}
			;
else_exp	: exp {}
			;
/*********************************************************/

%%

void yyerror(const char *message)
{
	fprintf(stderr, "%s\n", message);
}

int load_id(char *id)
{
	for(t=0;t<data_top;t++) {
		if(strncmp(data[t].sval, id, 64)==0) {
			return(data[t].ival);
		}
	}
}

int main(int argc, char *argv[]) {
	yyparse();
	return(0);
}