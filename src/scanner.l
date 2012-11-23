%{
#include "y.tab.h"
#include <stdlib.h>
#include <stdio.h>
%}


%option yylineno

%%

[[:blank:]\n]	;
^#.*	{ yylval.strval=strdup(yytext); return(PREPROCESSOR_STATEMENT);}

"if"	return(IF);
"while"	return(WHILE); 
"return" return(RETURN);
"def"    return (DEF);
"var"	 return(VAR);
"=="	return(EQUIV);
"<"		return(LT);
">"		return(GT);
"<="	return(LE);
">="	return(GE);
"+"		return(PLUS);
"-"		return(MINUS);
"*"		return(TIMES);
"/"		return(DIVIDE);
"("		return(OPEN_PARENTHESIS);
")"		return(CLOSE_PARENTHESIS);
"{"		return(OPEN_BRACE);
"}"		return(CLOSE_BRACE);
","		return(COMA);
";"		return(END_OF_LINE);
"="		return(EQUALS);

printf(.*)	{ return frontend(); }
scanf(.*)	{ return frontend(); }

int {yylval.strval=strdup(yytext); return(TYPE);}
char {yylval.strval=strdup(yytext); return(TYPE); }


[[:digit:]]+	{ yylval.strval=strdup(yytext); return(CONST);}
[_[:alpha:]][_[:alnum:]]*	{yylval.strval=strdup(yytext);return(NAME);}

.	printf("PUNTO + %s\n", yytext);


%%

int
frontend() {
	int len = strlen(yytext);
	if ( yytext[len - 1] == ';' ) {
	yyless(len-1);
	}
	yylval.strval = strdup(yytext);
	return(IO_CALL); 
}

