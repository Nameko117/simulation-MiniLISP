%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *message);

typedef struct NODE {
	char type;
	int ival;
	char* sval;
	struct NODE *L;
	struct NODE *R;
	/*
	type:
	(char)
	+ - * / > < =
	(number 1~30 64~)
	1 NUMBER, 2 BOOL_VAL
	5 MOD
	6 AND, 7 OR, 8 NOT
	9 IF, 10 IF NEXT
	11 DEFINE, 12 variable
	*/
} node;

node data[256];
int data_top = 0;

node* makeN(char type, int ival, char* sval, node* L, node* R);
node* exeN(node* n);
node* numN(node* n);
node* cmpN(node* n);
node* lgcN(node* n);
node* ifN(node* n);
void defDataN(node* n);
node* dataN(node* n);
%}

%union {
	int ival;
	char sval[16];
	struct NODE* nval;
}

%token PRINT_NUM PRINT_BOOL
%token<ival> BOOL_VAL NUMBER
%token MOD
%token AND OR NOT
%token DEFINE FUN
%token<sval> ID
%token IF

/*********************************************************/

%type<nval> start

%type<nval> program

%type<nval> stmt
%type<nval> print_stmt

%type<nval> exp

%type<nval> num_op 
%type<nval> plus minus multiply divide modulus
%type<nval> greater smaller equal
%type<nval> plus_exps multi_exps
%type<nval> equal_exps

%type<nval> logical_op
%type<nval> and_op or_op not_op
%type<nval> and_exps or_exps

%type<nval> def_stmt
%type<nval> variable

%type<nval> fun_exp fun_ids fun_body fun_call
%type<nval> param /*last_exp*/ fun_name
%type<nval> ids params

%type<nval> if_exp test_exp then_exp else_exp

%%

start		: program {}
			;
program		: stmt program {}
			| stmt {}
			;
stmt		: exp { free(exeN($1)); }
			| def_stmt { defDataN($1); }
			| print_stmt {}
			;
print_stmt	: '(' PRINT_NUM exp ')' {
				node* tmpN = exeN($3);
				if(!tmpN) { printf("error\n"); }
				else if(tmpN->type!=1) yyerror("Type Error: Expect ‘number’ but got ‘boolean’.");
				else printf("%d\n", tmpN->ival);
				free(tmpN);
			}
			| '(' PRINT_BOOL exp ')' {
				node* tmpN = exeN($3);
				if(!tmpN) { printf("error\n"); }
				else if(tmpN->type!=2) yyerror("Type Error: Expect ‘boolean’ but got ‘number’.");
				else {
					if(tmpN->ival) printf("#t\n");
					else printf("#f\n");
				}
				free(tmpN);
			}
			;
exp			: BOOL_VAL { $$ = makeN(2, $1, "", 0, 0); }
			| NUMBER { $$ = makeN(1, $1, "", 0, 0); }
			| variable {}
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
plus		: '(' '+' plus_exps ')' { $$ = $3;}
			;
plus_exps	: plus_exps exp { $$ = makeN('+', 0, "", $1, $2); }
			| exp exp { $$ = makeN('+', 0, "", $1, $2); }
			;
minus		: '(' '-' exp exp ')' { $$ = makeN('-', 0, "", $3, $4); }
			;
multiply	: '(' '*' multi_exps ')' { $$ = $3; }
			;
multi_exps	: multi_exps exp { $$ = makeN('*', 0, "", $1, $2); }
			| exp exp { $$ = makeN('*', 0, "", $1, $2); }
			;
divide		: '(' '/' exp exp ')' { $$ = makeN('/', 0, "", $3, $4); }
			;
modulus		: '(' MOD exp exp ')' { $$ = makeN(5, 0, "", $3, $4); }
			;
greater		: '(' '>' exp exp ')' { $$ = makeN('>', 0, "", $3, $4); }
			;
smaller		: '(' '<' exp exp ')' { $$ = makeN('<', 0, "", $3, $4); }
			;
equal		: '(' '=' equal_exps ')' { $$ = $3; }
			;
equal_exps	: equal_exps exp { $$ = makeN('=', 0, "", $1, $2); }
			| exp exp { $$ = makeN('=', 0, "", $1, $2); }
			;
/*********************************************************/
logical_op	: and_op {}
			| or_op {}
			| not_op {}
			;
and_op		: '(' AND and_exps ')' { $$ = $3; }
			;
and_exps	: and_exps exp { $$ = makeN(6, 0, "", $1, $2); }
			| exp exp { $$ = makeN(6, 0, "", $1, $2); }
			;
or_op		: '(' OR or_exps ')' { $$ = $3; }
			;
or_exps		: or_exps exp { $$ = makeN(7, 0, "", $1, $2); }
			| exp exp { $$ = makeN(7, 0, "", $1, $2); }
			;
not_op		: '(' NOT exp ')' { $$ = makeN(8, 0, "", $3, 0); }
			;
/*********************************************************/
def_stmt	: '(' DEFINE variable exp ')' { $$ = makeN(11, 0, "", $3, $4); }
			;
variable	: ID {
				char* tmpS = malloc(sizeof($1));
				sprintf(tmpS, "%s", $1);
				$$ = makeN(12, 0, tmpS, 0, 0); 
			}
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
				node* tmp = makeN(10, 0, "", $4, $5);
				$$ = makeN(9, 0, "", $3, tmp);
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

node* makeN(char type, int ival, char* sval, node* L, node* R)
{
	node *tmpN = malloc(sizeof(node));
	
	tmpN->type = type;
	tmpN->ival = ival;
	tmpN->sval = sval;
	tmpN->L = L;
	tmpN->R = R;

	return tmpN;
}

node* exeN(node* n)
{
	if(!n) return(0);
	//printf("%d\n", n->type);
	switch(n->type) {
		case 1: //NUMBER
		case 2: //BOOL_VAL
			return(makeN(n->type, n->ival, "", 0, 0));
			break;
		case '+':
		case '-':
		case '*':
		case '/':
		case 5://MOD
			return(numN(n));
			break;
		case '>':
		case '<':
		case '=':
			return(cmpN(n));
			break;
		case 6://AND
		case 7://OR
		case 8://NOT
			return(lgcN(n));
			break;
		case 9://IF
			return(ifN(n));
			break;
		case 10://IF NEXT
			return(makeN(10, 0, "", n->L, n->R));
			break;
		case 12://variable
			return(dataN(n));
			break;
		default:
			printf("error type:%d", n->type);
			break;
	}
}

node* numN(node* n)
{
	if(!n) return(0);
	node* tmpL = exeN(n->L);
	node* tmpR = exeN(n->R);
	if(!tmpL || !tmpR) return(0);
	if(tmpL->type!=1 || tmpR->type!=1) {
		yyerror("Type Error: Expect ‘number’ but got ‘boolean’.");
		return(0);
	}
	int output;
	switch(n->type) {
		case '+':
			output = tmpL->ival + tmpR->ival;
			break;
		case '-':
			output = tmpL->ival - tmpR->ival;
			break;
		case '*':
			output = tmpL->ival * tmpR->ival;
			break;
		case '/':
			output = tmpL->ival / tmpR->ival;
			break;
		case 5://MOD
			output = tmpL->ival % tmpR->ival;
			break;
	}
	free(tmpL);
	free(tmpR);
	return(makeN(1, output, "", 0, 0));
}

node* cmpN(node* n)
{
	if(!n) return(0);
	node* tmpL = exeN(n->L);
	node* tmpR = exeN(n->R);
	if(!tmpL || !tmpR) return(0);
	if(tmpL->type!=1 || tmpR->type!=1) {
		yyerror("Type Error: Expect ‘number’ but got ‘boolean’.");
		return(0);
	}
	int output;
	switch(n->type) {
		case '>':
			output = tmpL->ival > tmpR->ival;
			break;
		case '<':
			output = tmpL->ival < tmpR->ival;
			break;
		case '=':
			output = tmpL->ival == tmpR->ival;
			break;
	}
	free(tmpL);
	free(tmpR);
	return(makeN(2, output, "", 0, 0));
}

node* lgcN(node* n)
{
	if(!n) return(0);
	node* tmpL = exeN(n->L);
	node* tmpR = exeN(n->R);
	if(!tmpL) return(0);
	if(tmpL->type!=2) {
		yyerror("Type Error: Expect ‘boolean’ but got ‘number’.");
		return(0);
	}
	int output;
	switch(n->type) {
		case 6://AND
			if(!tmpR) return(0);
			if(tmpR->type!=2) {
				yyerror("Type Error: Expect ‘boolean’ but got ‘number’.");
				return(0);
			}
			output = tmpL->ival && tmpR->ival;
			break;
		case 7://OR
			if(!tmpR) return(0);
			if(tmpR->type!=2) {
				yyerror("Type Error: Expect ‘boolean’ but got ‘number’.");
				return(0);
			}
			output = tmpL->ival || tmpR->ival;
			break;
		case 8://NOT
			output = !tmpL->ival;
			break;
	}
	free(tmpL);
	free(tmpR);
	return(makeN(2, output, "", 0, 0));
}

node* ifN(node* n)
{
	if(!n) return(0);
	node* tmpL = exeN(n->L);
	node* tmpR = exeN(n->R);
	if(!tmpL || !tmpR) return(0);
	if(tmpL->type!=2) {
		yyerror("Type Error: Expect ‘boolean’ but got ‘number’.");
		return(0);
	}
	node* output;
	if(tmpL->ival) output = exeN(tmpR->L);
	else output = exeN(tmpR->R);
	free(tmpL);
	free(tmpR);
	return(output);
}

void defDataN(node* n)
{
	if(!n) return;
	node* tmpL = n->L;
	node* tmpR = exeN(n->R);
	if(!tmpL || !tmpR) return;
	if(dataN(tmpL)) printf("Redefining is not allowed.\n");
	if(data_top<256) {
		data[data_top].type = tmpR->type;
		data[data_top].ival = tmpR->ival;
		data[data_top].sval = tmpL->sval;
		data_top++;
	}
	else printf("Memory is not enough.\n");
}

node* dataN(node* n)
{
	if(!n) return(0);
	node* output = 0;
	int i;
	for(i=data_top-1;i>-1;i--) {
		if(strncmp(data[i].sval, n->sval, sizeof(n->sval))==0) {
			output = makeN(data[i].type, data[i].ival, "", 0, 0);
			break;
		}
	}
	return(output);
}

void yyerror(const char *message)
{
	fprintf(stderr, "%s\n", message);
}

int main(int argc, char *argv[]) {
	yyparse();
	return(0);
}