%{
#include "y.tab.h"
#include <stdlib.h>
#include <stdio.h>
%}


%option yylineno

%%

[[:blank:]\n]	;
^#.*	{ yylval.strval=strdup(yytext); return(PREPROCESSOR_STATEMENT);}
"("	return(LEFT_PARENTHESIS);
")"	return(RIGHT_PARENTHESIS);
"{"	return(LEFT_BRACE);
"}"	return(RIGHT_BRACE);
","	return(COMA);
";"	return(SEMI_COLON);
"="	return(EQUALS);
"if"	return(IF);
"while"	return(WHILE); 
"=="	return(EQUALS_COND);
"<"	return(LT);
">"	return(GT);
"<="	return(LE);
">="	return(GE);
"+"	return(PLUS);
"-"	return(MINUS);
"*"	return(TIMES);
"/"	return(DIVIDE);
printf(.*)	{ return ioFunction(); }
scanf(.*)	{ return ioFunction(); }
int {yylval.strval=strdup(yytext); return(TYPE);}
char {yylval.strval=strdup(yytext); return(TYPE); }
[[:digit:]]+	{ yylval.strval=strdup(yytext); return(CONST);}
[_[:alpha:]][_[:alnum:]]*	{yylval.strval=strdup(yytext);return(ID);}
.	printf("PUNTO + %s\n", yytext);


%%

int
ioFunction() {
	int len = strlen(yytext);
	if ( yytext[len - 1] == ';' ) {
	yyless(len-1);
	}
	yylval.strval = strdup(yytext);
	return(IO_CALL); 
}

