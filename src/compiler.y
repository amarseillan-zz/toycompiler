%union{
	char * strval;
}

/* Inicio de todo */
%start PROGRAM


/* Simbolos aceptados: ; , = ( ) [ ] */
%token SEMI_COLON COMA EQUALS LEFT_PARENTHESIS RIGHT_PARENTHESIS LEFT_BRACE RIGHT_BRACE

/* Simbolos aceptados: == < > >= <=  */
%token EQUALS_COND LT GT LE GE

/* Comandos aceptados: while, if  */
%token WHILE IF




/* Simbolos aceptados: + - * /  */
%token PLUS MINUS TIMES DIVIDE


/* Precedencias  */

%left PLUS MINUS TIMES DIVIDE CONST


%token <strval> CONST
%token <strval> ID
%token <strval> TYPE

%token <strval> IO_CALL
%token <strval> PREPROCESSOR_STATEMENT

%type <strval> I
%type <strval> D
%type <strval> CONTROL_SEQ
%type <strval> ASSIGN
%type <strval> PARAM_LIST
%type <strval> COND_OP
%type <strval> CONDITION
%type <strval> FUNCTION_CALL
%type <strval> P
%type <strval> FUNCTIONS
%type <strval> FORMAL_PARAMETER
%type <strval> FORMAL_PARAMETERS_LIST
%type <strval> PREPROCESSOR


%{

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>


extern FILE * yyin;
extern FILE * yyout;
extern int yylineno;

FILE * outputFile = NULL;

char * createString(int, char *[], const char *, int);

char * operandString(char *, char *, char *);

char * operandSufixString(char *, char *, char *, char *);



typedef enum {
	CHAR,
	INT,
	FUNCTION
} SymbolType;

typedef struct Symbol {
	char * symbol;
	SymbolType type;
} Symbol;

typedef struct SymbolTable {
	int size;
	int maxSize;
	Symbol ** table;
} SymbolTable;

bool addSymbol(SymbolTable *, char *, SymbolType);

void clearSymbolTable(SymbolTable *);

bool symbolExists(SymbolTable *, char *);

char * constantMathString(char *, char *, int);


SymbolType stringToSymbolType(char *);



SymbolTable symbolTable;
SymbolTable functionSymbols;

%}

%error-verbose

%%


PROGRAM:	PREPROCESSOR FUNCTIONS { fprintf(outputFile, "%s%s", $1, $2); };
PREPROCESSOR:	PREPROCESSOR PREPROCESSOR_STATEMENT { 	char * strs[2] = { $1, $2 };
							$$ = createString(2, strs, "%s%s\n", 2); }
		| { $$ = ""; }
		;
FUNCTIONS:	FUNCTIONS TYPE ID LEFT_PARENTHESIS FORMAL_PARAMETERS_LIST RIGHT_PARENTHESIS LEFT_BRACE P RIGHT_BRACE {
			if ( !addSymbol(&functionSymbols, $3, FUNCTION) ) {
				char * strs[2] = { "Redefinition of", $3};
				yyerror(createString(2, strs, "%s %s", 2));
				YYABORT;
			}
			char * strs[5] = {$1, $2, $3, $5, $8};
			clearSymbolTable(&symbolTable);
			$$ = createString(5, strs, "%s\n%s\n%s(%s) {\n%s\n}", 10);
		}
		| { $$ = ""; }
		;
FORMAL_PARAMETERS_LIST:	FORMAL_PARAMETER { $$ = $1; }
			| FORMAL_PARAMETER COMA FORMAL_PARAMETERS_LIST { $$ = operandString($1, ", ", $3); }	
			| { $$ = ""; }
			;
FORMAL_PARAMETER: TYPE ID {	if ( !addSymbol(&symbolTable, $2, stringToSymbolType($1)) ) {
					char * strs[2] = { "Redefinition of", $2 };
					yyerror(createString(2, strs, "%s %s", 2));
					YYABORT;
				}
				$$ = operandString($1, " ", $2); };
P:	P I SEMI_COLON {	$$ = operandSufixString($1, "\n ", $2, ";"); }
	| P D SEMI_COLON {  	$$ = operandSufixString($1, "\n", $2, ";"); }
	| P CONTROL_SEQ	{	$$ = operandString($1, "\n", $2); }
	| { $$ = ""; }
	;
D:	FORMAL_PARAMETER	{ $$ = $1; }
	| TYPE ID EQUALS ASSIGN	{	char * strs[3] = {$1, $2, $4};
					if ( !addSymbol(&symbolTable, $2, stringToSymbolType($1)) ) {
						char * strs[2] = { "Redefinition of", $2 };
						yyerror(createString(2, strs, "%s %s", 2));
						YYABORT;
					}
					$$ = createString(3, strs, "%s %s = %s", 5); }
	| TYPE ID EQUALS CONST {	char * strs[3] = {$1, $2, $4};
                                        if ( !addSymbol(&symbolTable, $2, stringToSymbolType($1)) ) {
                                                char * strs[2] = { "Redefinition of", $2 };
                                                yyerror(createString(2, strs, "%s %s", 2));
                                                YYABORT;
                                        }
                                        $$ = createString(3, strs, "%s %s = %s", 5); }
	;
I:	ID EQUALS ASSIGN {	if ( !symbolExists(&symbolTable, $1) ) {
					char * strs[2] = { "Missing definition of", $1 };
					yyerror(createString(2, strs, "%s %s", 2));
					YYABORT;
				}
				$$ = operandString($1, " = ", $3); }
	| ID EQUALS CONST {	if ( !symbolExists(&symbolTable, $1) ) {
                                	char * strs[2] = { "Missing definition of", $1 };
                                        yyerror(createString(2, strs, "%s %s", 2));
                                        YYABORT;
                                }
                                $$ = operandString($1, " = ", $3); }
	| FUNCTION_CALL	{ $$ = $1; }
	;

FUNCTION_CALL: 	ID LEFT_PARENTHESIS PARAM_LIST RIGHT_PARENTHESIS {  	if ( !symbolExists(&symbolTable, $1) ) {
                                 					       char * strs[2] = { "Missing definition of", $1 };
					                                       yyerror(createString(2, strs, "%s %s", 2));
					                                       YYABORT;
					                                }
									char * strs[2] = {$1, $3};
									$$ = createString(2, strs, "%s(%s)", 3); }
		| IO_CALL { $$ = $1; }
		;

PARAM_LIST:	ASSIGN	{ $$ = $1; }
		| CONST { $$ = $1; }
		| CONST COMA PARAM_LIST { $$ = operandString($1, ", ", $3); }
		| ASSIGN COMA PARAM_LIST { $$ = operandString($1, ", ", $3); }
		;
ASSIGN:	ID	{	if ( !symbolExists(&symbolTable, $1) ) {
				char * strs[2] = { "Missing definition of", $1 };
				yyerror(createString(2, strs, "%s %s", 2));
				YYABORT;
			} 
			$$ = $1; }
	| LEFT_PARENTHESIS ASSIGN RIGHT_PARENTHESIS	{ 	char * strs[1] = {$2}; 
						$$ = createString(1, strs, "( %s )", 4); }
	| ASSIGN PLUS ASSIGN	{ $$ = operandString($1, " + ", $3); }
	| ASSIGN MINUS ASSIGN 	{ $$ = operandString($1, " - ", $3); }
	| ASSIGN TIMES ASSIGN	{ $$ = operandString($1, " * ", $3); }
	| ASSIGN DIVIDE ASSIGN	{ $$ = operandString($1, " / ", $3); }
	| ASSIGN PLUS CONST	{ $$ = operandString($1, " + ", $3); }
	| ASSIGN MINUS CONST	{ $$ = operandString($1, " - ", $3); }
	| ASSIGN TIMES CONST	{ $$ = operandString($1, " * ", $3); }
	| ASSIGN DIVIDE CONST	{ $$ = operandString($1, " / ", $3); }
	| CONST PLUS ASSIGN	{ $$ = operandString($1, " + ", $3); }
	| CONST MINUS ASSIGN	{ $$ = operandString($1, " - ", $3); }
	| CONST TIMES ASSIGN	{ $$ = operandString($1, " * ", $3); }
	| CONST DIVIDE ASSIGN	{ $$ = operandString($1, " / ", $3); }
	| CONST PLUS CONST	{ $$ = constantMathString($1, $3, PLUS); }
	| CONST MINUS CONST	{ $$ = constantMathString($1, $3, MINUS); }
	| CONST TIMES CONST	{ $$ = constantMathString($1, $3, TIMES); }
	| CONST DIVIDE CONST	{ $$ = constantMathString($1, $3, DIVIDE); }
	| FUNCTION_CALL 	{ $$ = $1; }
	;
CONTROL_SEQ:	IF LEFT_PARENTHESIS CONDITION RIGHT_PARENTHESIS LEFT_BRACE P RIGHT_BRACE {	
				char * str = malloc(strlen($3) + strlen($6) + 13);
				sprintf(str, "if ( %s ) {\n%s\n}", $3, $6);
				$$ = str; }
												
		| WHILE LEFT_PARENTHESIS CONDITION RIGHT_PARENTHESIS LEFT_BRACE P RIGHT_BRACE {
				char * str = malloc(strlen($3) + strlen($6) + 16);
				sprintf(str, "while ( %s ) {\n%s\n}", $3, $6);
				$$ = str; }
		;
CONDITION:	ASSIGN COND_OP ASSIGN {	char * strs[3] = { $1, $2, $3};
					$$ = createString(3, strs, "%s %s %s", 4); }
		| CONST COND_OP CONST { char * strs[3] = { $1, $2, $3};
                                        $$ = createString(3, strs, "%s %s %s", 4); }
		| CONST COND_OP ASSIGN {	char * strs[3] = { $1, $2, $3};
						$$ = createString(3, strs, "%s %s %s", 4); }
		| ASSIGN COND_OP CONST {	char * strs[3] = { $1, $2, $3};
	                                        $$ = createString(3, strs, "%s %s %s", 4); }
COND_OP:	EQUALS_COND { $$ = "=="; }
		| GT	{ $$ = ">"; }
		| LT	{ $$ = "<"; }
		| LE	{ $$ = "<="; }
		| GE	{ $$ = ">="; }
		;

%%

char *
createString(int size, char * strs[], const char * format, int constant) {
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
operandString(char * str1, char * operand,char * str2) {
	char * strs[2] = {str1, str2};
	int len = strlen(operand);
	char * format = malloc(len + 5);
	sprintf(format, "%%s%s%%s", operand);
	return createString(2, strs, format, len+1);
}

char *
constantMathString(char * c1, char * c2, int mathOp) {
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
operandSufixString(char * str1, char * operand, char * str2, char * sufix) {
	char * dest = malloc(strlen(str2) + strlen(sufix) + 1);
	strcpy(dest, str2);
	strcat(dest, sufix);
	return operandString(str1, operand, dest);
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
addSymbol(SymbolTable * symbolTable, char * symbol, SymbolType type) {
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

SymbolType
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

	char * outputFileName = NULL, * inputFileName = NULL;
	FILE * inputFile;
	if ( argc >= 2 ) {
		int i;
		for ( i = 1 ; i < argc ; i++ ) {
			if ( !strcmp(argv[i], "-o") ) {
				if ( i + 1 < argc ) {
					outputFileName = argv[i+1];
					i++;
				} else {
					printf("Missing file name\n");
					return 1;
				}
			} else {
				if ( inputFileName == NULL ) {
					inputFileName = argv[i];
				} else {
					printf("Unknown parameter %s\n", argv[i]);
					return 1;
				}
			}
		}
		if ( outputFileName == NULL ) {
			outputFileName = "./out.c";
		}
	} else {
		printf("Input file missing\n");
		return 1;
	}
	
	outputFile = fopen(outputFileName, "w");
	if ( outputFile == NULL ) {
		printf("Couldn't open output file\n");
		return 1;
	}
	inputFile = fopen(inputFileName, "r");
	if ( inputFile == NULL ) {
		printf("Couldn't open input file\n");
		return 1;
	}
	yyin = inputFile;
	yyout = outputFile;
	initTable(&symbolTable);
	initTable(&functionSymbols);
	yyparse();
	fclose(inputFile);
	fclose(outputFile);
}
