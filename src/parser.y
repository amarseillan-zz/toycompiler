%union{
	char * strval;
}

/* Inicio de todo */
%start PROGRAM


/* Simbolos aceptados: ; , = ( ) [ ] */
%token END_OF_LINE COMA EQUALS LEFT_PARENTHESIS RIGHT_PARENTHESIS LEFT_BRACE RIGHT_BRACE

/* Simbolos aceptados: == < > >= <=  */
%token EQUIV LT GT LE GE

/* Comandos aceptados: while, if  */
%token WHILE IF RETURN DEF VAR



/* Simbolos aceptados: + - * /  */
%token PLUS MINUS TIMES DIVIDE


/* Precedencias  */

%left PLUS MINUS TIMES DIVIDE CONST


%token <strval> CONST
%token <strval> NAME
%token <strval> TYPE

%token <strval> IO_CALL
%token <strval> PREPROCESSOR_STATEMENT

%type <strval> I
%type <strval> D
%type <strval> CONTROL
%type <strval> VAL
%type <strval> PARAM_LIST
%type <strval> COND_OP
%type <strval> CONDITION
%type <strval> CALL
%type <strval> VAR P
%type <strval> FUNC
%type <strval> FUNC_DEF
%type <strval> PARAM
%type <strval> PARAMETERS
%type <strval> PREPROCESSOR


%{

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
extern FILE * yyin;
extern FILE * yyout;
extern int yylineno;

FILE * out_file = NULL;

char * concat(int, char *[], const char *, int);
char * concat_op(char *, char *, char *, char *);
char * print_op(char *, char *, char *);


typedef enum {
	CHAR,
	INT,
	FUNCTION
} Type;

typedef struct Symbol {
	char * symbol;
	Type type;
} Symbol;

typedef struct SymbolTable {
	int size;
	int maxSize;
	Symbol ** table;
} SymbolTable;

bool addSymbol(SymbolTable *, char *, Type);
void clearSymbolTable(SymbolTable *);
bool symbolExists(SymbolTable *, char *);
char * math_operation(char *, char *, int);


Type stringToSymbolType(char *);



SymbolTable symbolTable;
SymbolTable functionSymbols;




%}

%error-verbose

%%


PROGRAM:	PREPROCESSOR FUNC_DEF FUNC { fprintf(out_file, "%s%s%s", $1, $2, $3); };

PREPROCESSOR:	PREPROCESSOR PREPROCESSOR_STATEMENT { 	

	char * strs[2] = { $1, $2 };
	$$ = concat(2, strs, "%s%s\n", 2);
}	| { 

	$$ = ""; 
};
		
FUNC_DEF:  FUNC_DEF DEF TYPE NAME PARAMETERS END_OF_LINE {

			if ( !addSymbol(&functionSymbols, $4, FUNCTION) ) {

				char * strs[2] = {"Redefining function", $4};
				yyerror(concat(2, strs, "%s %s", 2));
				YYABORT;

			}

			char * strs[5] = {$1, $3, $4, $5};
			clearSymbolTable(&symbolTable);

			$$ = concat(4, strs, "%s\n%s\n%s(%s);", 5);
		}

		| { $$ = ""; }
		;
						
			
FUNC:	FUNC TYPE NAME LEFT_PARENTHESIS PARAMETERS RIGHT_PARENTHESIS LEFT_BRACE P RIGHT_BRACE {
			if ( !symbolExists(&functionSymbols, $3) ) {
				char * strs[2] = { $3, "has no signature!"};
				yyerror(concat(2, strs, "%s %s", 2));
				YYABORT;
			}
			char * strs[5] = {$1, $2, $3, $5, $8};
			clearSymbolTable(&symbolTable);
			$$ = concat(5, strs, "%s\n%s\n%s(%s) {\n%s\n}", 10);
		}
		| { $$ = ""; }
		;

PARAMETERS:	PARAM { $$ = $1; }
			| PARAM COMA PARAMETERS { $$ = print_op($1, ", ", $3); }	
			| { $$ = ""; }
			;

PARAM: VAR TYPE NAME {	if ( !addSymbol(&symbolTable, $3, stringToSymbolType($2)) ) {
					char * strs[2] = { "Redefinition of", $3 };
					yyerror(concat(2, strs, "%s %s", 2));
					YYABORT;
				}
				$$ = print_op($2, " ", $3); };

P:	P I END_OF_LINE {	$$ = concat_op($1, "\n ", $2, ";"); }
	| P D END_OF_LINE {  	$$ = concat_op($1, "\n", $2, ";"); }
	| P CONTROL	{	$$ = print_op($1, "\n", $2); }
	| { $$ = ""; }
	;

D:	PARAM	{ $$ = $1; }
	| VAR TYPE NAME EQUALS VAL	{	char * strs[3] = {$2, $3, $5};
					if ( !addSymbol(&symbolTable, $3, stringToSymbolType($2)) ) {
						char * strs[2] = { "Redefinition of", $3 };
						yyerror(concat(2, strs, "%s %s", 2));
						YYABORT;
					}
					$$ = concat(3, strs, "%s %s = %s", 5); }
	| VAR TYPE NAME EQUALS CONST {	char * strs[3] = {$2, $3, $5};
                                        if ( !addSymbol(&symbolTable, $3, stringToSymbolType($2)) ) {
                                                char * strs[2] = { "Redefinition of", $3 };
                                                yyerror(concat(2, strs, "%s %s", 2));
                                                YYABORT;
                                        }
                                        $$ = concat(3, strs, "%s %s = %s", 5); }
    | RETURN VAL {	char * strs[1] = {$2};
    					$$ = concat(1, strs, "return %s", 8); }
    | RETURN CONST {		char * strs[1] = {$2};
    					$$ = concat(1, strs, "return %s", 8); }
	;
I:	NAME EQUALS VAL {	if ( !symbolExists(&symbolTable, $1) ) {
					char * strs[2] = { "Missing definition of", $1 };
					yyerror(concat(2, strs, "%s %s", 2));
					YYABORT;
				}
				$$ = print_op($1, " = ", $3); }
	| NAME EQUALS CONST {	if ( !symbolExists(&symbolTable, $1) ) {
                                	char * strs[2] = { "Missing definition of", $1 };
                                        yyerror(concat(2, strs, "%s %s", 2));
                                        YYABORT;
                                }
                                $$ = print_op($1, " = ", $3); }
	| CALL	{ $$ = $1; }
	;

CALL: 	NAME LEFT_PARENTHESIS PARAM_LIST RIGHT_PARENTHESIS {  	if ( !symbolExists(&functionSymbols, $1) ) {
                                 					       char * strs[2] = { "Missing definition of", $1 };
					                                       yyerror(concat(2, strs, "%s %s", 2));
					                                       YYABORT;
					                                }
									char * strs[2] = {$1, $3};
									$$ = concat(2, strs, "%s(%s)", 3); }
		| IO_CALL { $$ = $1; }
		;

PARAM_LIST:	VAL	{ $$ = $1; }
		| CONST { $$ = $1; }
		| CONST COMA PARAM_LIST { $$ = print_op($1, ", ", $3); }
		| VAL COMA PARAM_LIST { $$ = print_op($1, ", ", $3); }
		;
VAL:	NAME	{	if ( !symbolExists(&symbolTable, $1) ) {
				char * strs[2] = { "Missing definition of", $1 };
				yyerror(concat(2, strs, "%s %s", 2));
				YYABORT;
			} 
			$$ = $1; }
	| LEFT_PARENTHESIS VAL RIGHT_PARENTHESIS	{ 	char * strs[1] = {$2}; 
						$$ = concat(1, strs, "( %s )", 4); }
	| VAL PLUS VAL	{ $$ = print_op($1, " + ", $3); }
	| VAL MINUS VAL 	{ $$ = print_op($1, " - ", $3); }
	| VAL TIMES VAL	{ $$ = print_op($1, " * ", $3); }
	| VAL DIVIDE VAL	{ $$ = print_op($1, " / ", $3); }
	| VAL PLUS CONST	{ $$ = print_op($1, " + ", $3); }
	| VAL MINUS CONST	{ $$ = print_op($1, " - ", $3); }
	| VAL TIMES CONST	{ $$ = print_op($1, " * ", $3); }
	| VAL DIVIDE CONST	{ $$ = print_op($1, " / ", $3); }
	| CONST PLUS VAL	{ $$ = print_op($1, " + ", $3); }
	| CONST MINUS VAL	{ $$ = print_op($1, " - ", $3); }
	| CONST TIMES VAL	{ $$ = print_op($1, " * ", $3); }
	| CONST DIVIDE VAL	{ $$ = print_op($1, " / ", $3); }
	| CONST PLUS CONST	{ $$ = math_operation($1, $3, PLUS); }
	| CONST MINUS CONST	{ $$ = math_operation($1, $3, MINUS); }
	| CONST TIMES CONST	{ $$ = math_operation($1, $3, TIMES); }
	| CONST DIVIDE CONST	{ $$ = math_operation($1, $3, DIVIDE); }
	| CALL 	{ $$ = $1; }
	;
CONTROL:	IF LEFT_PARENTHESIS CONDITION RIGHT_PARENTHESIS LEFT_BRACE P RIGHT_BRACE {	
				char * str = malloc(strlen($3) + strlen($6) + 13);
				sprintf(str, "if ( %s ) {\n%s\n}", $3, $6);
				$$ = str; }
												
		| WHILE LEFT_PARENTHESIS CONDITION RIGHT_PARENTHESIS LEFT_BRACE P RIGHT_BRACE {
				char * str = malloc(strlen($3) + strlen($6) + 16);
				sprintf(str, "while ( %s ) {\n%s\n}", $3, $6);
				$$ = str; }
		;
CONDITION:	VAL COND_OP VAL {	char * strs[3] = { $1, $2, $3};
					$$ = concat(3, strs, "%s %s %s", 4); }
		| CONST COND_OP CONST { char * strs[3] = { $1, $2, $3};
                                        $$ = concat(3, strs, "%s %s %s", 4); }
		| CONST COND_OP VAL {	char * strs[3] = { $1, $2, $3};
						$$ = concat(3, strs, "%s %s %s", 4); }
		| VAL COND_OP CONST {	char * strs[3] = { $1, $2, $3};
	                                        $$ = concat(3, strs, "%s %s %s", 4); }
COND_OP: EQUIV { $$ = "=="; }
		| GT	{ $$ = ">"; }
		| LT	{ $$ = "<"; }
		| LE	{ $$ = "<="; }
		| GE	{ $$ = ">="; }
		;

%%

char *
concat(int size, char * strs[], const char * format, int constant) {
	int len = constant;
	int i;
	for ( i = 0 ; i < size ; i++ ) {
		len += strlen(strs[i]);
	}
	char * str = malloc(len);
	switch(size) {
	case 1:
		sprintf(str, format, strs[0]); break;
	case 2:
		sprintf(str, format, strs[0], strs[1]); break;
	case 3:
		sprintf(str, format, strs[0], strs[1], strs[2]); break;
	case 4:
		sprintf(str, format, strs[0], strs[1], strs[2], strs[3]); break;
	case 5:
		sprintf(str, format, strs[0], strs[1], strs[2], strs[3], strs[4]); break;
	}
	return str;
}

char *
print_op(char * str1, char * operand,char * str2) {
	char * strs[2] = {str1, str2};
	int len = strlen(operand);
	char * format = malloc(len + 5);
	sprintf(format, "%%s%s%%s", operand);
	return concat(2, strs, format, len+1);
	
}

char *
math_operation(char * c1, char * c2, int mathOp) {

	int a = atoi(c1), b = atoi(c2);
	int res;
	switch(mathOp) {
	case PLUS:
		res = a + b; break;
	case MINUS:
		res = a - b; break;
	case TIMES:
		res = a * b; break;
	case DIVIDE:
		res = a / b; break;
	}
	int aux = res;
	int i = 1;
	aux /= 10;
	while ( aux > 0 ) {
		aux /= 10;
		i++;
	}
	bool neg = res < 0;
	int size = i + 1;
	if ( neg ) {
		size++;
	}
	char * str = malloc(size);
	sprintf(str, "%d", res);
	return str;
}

char *
concat_op(char * str1, char * operand, char * str2, char * sufix) {
	char * dest = malloc(strlen(str2) + strlen(sufix) + 1);
	strcpy(dest, str2);
	strcat(dest, sufix);
	return print_op(str1, operand, dest);
}

int yyerror(char *s) {
	fprintf(stderr, "%d: %s\n", yylineno, s);
}

#define TABLE_MAXSIZE_MULT 10

void
initTable(SymbolTable *  symbolTable) {
	symbolTable->table = malloc(TABLE_MAXSIZE_MULT*sizeof(char *));
	symbolTable->maxSize = TABLE_MAXSIZE_MULT;
	symbolTable->size = 0;
}

bool
addSymbol(SymbolTable * symbolTable, char * symbol, Type type) {
	if ( symbolExists(symbolTable, symbol) ) {
		return false;
	}
	if ( symbolTable->size == symbolTable->maxSize ) {
		symbolTable->maxSize += TABLE_MAXSIZE_MULT;
		symbolTable->table = realloc(symbolTable->table, (symbolTable->size + TABLE_MAXSIZE_MULT)*sizeof(Symbol*));
	}
	Symbol * newSymbol = malloc(sizeof(Symbol));
	newSymbol->symbol = symbol;
	newSymbol->type = type;
	symbolTable->table[symbolTable->size] = newSymbol;
	symbolTable->size++;
	return true;
}

bool
symbolExists(SymbolTable * symbolTable, char * symbol) {
	int i;
	for ( i = 0 ; i < symbolTable->size ; i++ ) {
		if ( !strcmp(symbolTable->table[i]->symbol, symbol) ) {
			return true;
		}
	}
	return false;
}

void
clearSymbolTable(SymbolTable * symbolTable) {
	symbolTable->size = 0;
}

Type
stringToSymbolType(char * string) {
	if ( !strcmp(string, "char") ) {
		return CHAR;
	} else if ( !strcmp(string, "int") ) {
		return INT;
	} else {
		return -1;
	}
}

int main(int argc, char * argv[]) {

	char * out = NULL, * in = NULL;

	FILE * in_file;
	
	if(argc > 1){

		in = argv[1];
		char name[50]={0};
		char new_name[50]={0};
		sscanf(in,"programs/%s",name);
		sprintf(new_name, "./%s.c",name);
		out=new_name;
	
	}
	else {

		printf("Input file missing\n");
		return 1;
	}

	out_file = fopen(out, "w");
	if ( out_file == NULL ) {
		printf("Couldn't open output file\n");
		return 1;
	}
	yyout = out_file;
	
	in_file = fopen(in, "r");
	if ( in_file == NULL ) {
		printf("Couldn't open input file\n");
		return 1;
	}
	yyin = in_file;


	initTable(&symbolTable);
	initTable(&functionSymbols);
	
	yyparse();
	
	fclose(in_file);
	fclose(out_file);
}
