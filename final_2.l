%{
#include "y.tab.h"
#include "string.h"
%}

separator	[ \t\n\r]
letter		[a-z]
digit		[0-9]

number		([0])|([1-9]{digit}*)|(\-[1-9]{digit}*)
ID			{letter}({letter}|{digit}|\-)*
bool-val	"#t"|"#f"

%%

{separator}	{ /*do nothing*/ }
"("|")"|"+"|"-"|"*"|"/"|">"|"<"|"=" { return(yytext[0]); }

"print-num"	{ return(PRINT_NUM); }
"print-bool" { return(PRINT_BOOL); }

{number}	{ yylval.ival = atoi(yytext); return(NUMBER); }
"#t"		{ yylval.ival = 1; return(BOOL_VAL); }
"#f"		{ yylval.ival = 0; return(BOOL_VAL); }

"mod"		{ return(MOD); }

"and"		{ return(AND); }
"or"		{ return(OR); }
"not"		{ return(NOT); }

"define"	{ return(DEFINE); }
"fun"		{ return(FUN); }
"if"		{ return(IF); }
{ID}		{ sprintf(yylval.sval, "%s", yytext); return(ID); }

.			{ printf("error char %s\n", yytext); }

%%