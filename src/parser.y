%union{
	char * strval;
}

/* Inicio de todo */
%start PROGRAM


/* Simbolos aceptados: ; , = ( ) [ ] */
%token END_OF_LINE COMA EQUALS OPEN_PARENTHESIS CLOSE_PARENTHESIS OPEN_BRACE CLOSE_BRACE

/* Simbolos aceptados: == < > >= <=  */
%token EQUIV LT GT LE GE

/* Comandos aceptados: while, if  */
%token WHILE IF RETURN DEF VAR VOID



/* Simbolos aceptados: + - * /  */
%token PLUS MINUS TIMES DIVIDE


/* Precedencias  */

%left PLUS MINUS TIMES DIVIDE CONST


%token <strval> CONST
%token <strval> NAME
%token <strval> TYPE

%token <strval> IO_CALL
%token <strval> INCLUDE

%type <strval> PROCESS
%type <strval> DECLARE
%type <strval> CONTROL
%type <strval> VAL
%type <strval> VOID
%type <strval> PARAM
%type <strval> PARAM_USES
%type <strval> PARAM_DEFS
%type <strval> COND_OP
%type <strval> CONDITION
%type <strval> CALL
%type <strval> LINE
%type <strval> VAR
%type <strval> FUNC
%type <strval> FUNC_DEF
%type <strval> INCLUDES


%{

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdarg.h>


extern FILE * yyin;
extern FILE * yyout;
extern int yylineno;

FILE * out_file = NULL;


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



char* math_operation(int op1, int op2, int mathOp);
char* concat_str(int argc, ...);

char * concat(int, char *[], const char *, int);

Type stringToSymbolType(char *);



SymbolTable symbolTable;
SymbolTable functionSymbols;




%}

%error-verbose

%%


PROGRAM:	INCLUDES FUNC_DEF FUNC { fprintf(out_file, "%s%s%s", $1, $2, $3); };

INCLUDES:	INCLUDES INCLUDE { 		$$ = concat_str(3,$1,$2,"\n");}	
			| 				 { 		$$ = ""; 					  }
;

		
FUNC_DEF:  	FUNC_DEF DEF TYPE NAME PARAM_DEFS END_OF_LINE {

				if ( !addSymbol(&functionSymbols, $4, FUNCTION) ) {

					yyerror(concat_str(2, "Redefining function ",$4));
					YYABORT;

				}

			

				clearSymbolTable(&symbolTable);

				char * strs[4] = {$1, $3, $4, $5};
				$$ = concat(4, strs, "%s\n%s\n%s(%s);", 5);
				//$$=concat_str(8,$1,"\n",$3,"\n",$4,"(",$5,");");
			
			

			}

			| { $$ = ""; }
;
						
			
FUNC:		FUNC TYPE NAME OPEN_PARENTHESIS PARAM_DEFS CLOSE_PARENTHESIS OPEN_BRACE LINE CLOSE_BRACE {

			if ( !symbolExists(&functionSymbols, $3) ) {
				yyerror(concat_str(2, $3, " has no signature!"));
				YYABORT;
			}

				clearSymbolTable(&symbolTable);
				$$=concat_str(12 ,$1,"\n",$2,"\n",$3,"(",$5,") {","\n",$8,"\n","}");
			}

			| { $$ = ""; }
;

PARAM_DEFS:	PARAM { $$ = $1; }

			| PARAM COMA PARAM_DEFS		{ $$ = concat_str(4,$1, ", ", $3); }	

			| 							{ $$ = ""; }
;

PARAM: 		VAR TYPE NAME {	

				if ( !addSymbol(&symbolTable, $3, stringToSymbolType($2)) ) {
					yyerror(concat_str(2, "Redefinition of ",$3));
					YYABORT;
				}
				$$ = concat_str(4,$2, " ", $3); 
				}
;

LINE: 		LINE PROCESS END_OF_LINE 	{	$$ = concat_str(4,$1,"\n ",$2,";"); 	}
			| LINE DECLARE END_OF_LINE 	{ 	$$ = concat_str(4,$1, "\n", $2, ";");	}
			| LINE CONTROL				{	$$ = concat_str(3,$1, "\n", $2); 		}	
			| 							{ 	$$ = ""; 								}
;

DECLARE:	PARAM			{ $$ = $1; }

			| VAR TYPE NAME EQUALS VAL	{	
					
					if ( !addSymbol(&symbolTable, $3, stringToSymbolType($2)) ) {

						yyerror(concat_str(2, "Redefinition of ",$3));
						YYABORT;
					}

					$$ = concat_str(5, $2," ",$3," = ",$5); 
			}

			| VAR TYPE NAME EQUALS CONST {	
                     
                    if ( !addSymbol(&symbolTable, $3, stringToSymbolType($2)) ) {
                            
                            yyerror(concat_str(2, "Redefinition of ",$3));
                            YYABORT;
                    }
					$$ = concat_str(5, $2," ",$3," = ",$5); 
			}

 		   | RETURN VAL 	{	$$ = concat_str(2,"return ",$2); }

  		   | RETURN CONST 	{	$$ = concat_str(2,"return ",$2); }
;

PROCESS: 	NAME EQUALS VAL {	

					if ( !symbolExists(&symbolTable, $1) ) {
					
						yyerror(concat_str(2, "Missing definition of ",$1));
						YYABORT;
					}

					$$ = concat_str(3,$1, " = ", $3); 
			}

			| NAME EQUALS CONST {	

					if ( !symbolExists(&symbolTable, $1) ) {
                                		
                     	yyerror(concat_str(2, "Missing definition of ",$1));
                        YYABORT;
                    }
                                	
                    $$ = concat_str(3,$1, " = ", $3); 
             }
			| CALL { $$ = $1; }
;

CALL: 		NAME OPEN_PARENTHESIS PARAM_USES CLOSE_PARENTHESIS {  	

					if ( !symbolExists(&functionSymbols, $1) ) {
                                 		
                    	yyerror(concat_str(2, "Missing definition of ",$1));
                        YYABORT;
					}

					$$ = concat_str(4,$1,"(",$3,")");}
									
			| IO_CALL 					{ $$ = $1; }
;


PARAM_USES:	

			 VAL						{ $$ = $1; }
			| CONST 					{ $$ = $1; }
			| CONST COMA PARAM_USES 	{ $$ = concat_str(4,$1, ", ", $3); }
			| VAL COMA PARAM_USES 		{ $$ = concat_str(4,$1, ", ", $3); }
			| { $$ = ""; }
;

VAL:		NAME	{	

					if ( !symbolExists(&symbolTable, $1) ) {
				
						yyerror(concat_str(2, "Missing definition of ",$1));
                		YYABORT;
					} 
				
				$$ = $1; }

			| OPEN_PARENTHESIS VAL CLOSE_PARENTHESIS	{ 	
						  	  $$ = concat_str(3,"( ","$2"," )"); 	}
			| VAL PLUS VAL			{ $$ = concat_str(3, $1, " + ", $3); 	}
			| VAL PLUS CONST		{ $$ = concat_str(3,$1, " + ", $3);	 	}
			| CONST PLUS VAL		{ $$ = concat_str(3,$1, " + ", $3); 	}
			| CONST PLUS CONST		{ $$ = math_operation(atoi($1), atoi($3), PLUS); 	}
			| VAL MINUS VAL 		{ $$ = concat_str(3,$1, " - ", $3); 	}
			| VAL MINUS CONST		{ $$ = concat_str(3,$1, " - ", $3); 	}
			| CONST MINUS VAL		{ $$ = concat_str(3,$1, " - ", $3); 	}
			| CONST MINUS CONST		{ $$ = math_operation(atoi($1), atoi($3), MINUS); 	}
			| VAL TIMES VAL			{ $$ = concat_str(3,$1, " * ", $3); 	}
			| VAL TIMES CONST		{ $$ = concat_str(3,$1, " * ", $3); 	}
			| CONST TIMES VAL		{ $$ = concat_str(3,$1, " * ", $3); 	}
			| CONST TIMES CONST		{ $$ = math_operation(atoi($1), atoi($3), TIMES); 	}
			| VAL DIVIDE VAL		{ $$ = concat_str(3,$1, " / ", $3); 	}
			| VAL DIVIDE CONST		{ $$ = concat_str(3,$1, " / ", $3); 	}
			| CONST DIVIDE VAL		{ $$ = concat_str(3,$1, " / ", $3); 	}
			| CONST DIVIDE CONST	{ $$ = math_operation(atoi($1), atoi($3), DIVIDE);	}
			| CALL 					{ $$ = $1; 								}
;



CONTROL:	IF OPEN_PARENTHESIS CONDITION CLOSE_PARENTHESIS OPEN_BRACE LINE CLOSE_BRACE {	
				
				$$= concat_str(5 ,"if (",$3,") {\n",$6,"\n}");
			
			}
												
			| WHILE OPEN_PARENTHESIS CONDITION CLOSE_PARENTHESIS OPEN_BRACE LINE CLOSE_BRACE {
				
				$$= concat_str(5 ,"while (",$3,") {\n",$6,"\n}");
				
			}
;

CONDITION:	VAL COND_OP VAL 		{	$$ = concat_str(5, $1," ",$2," ",$3); }
			| CONST COND_OP CONST 	{ 	$$ = concat_str(5, $1," ",$2," ",$3); }
			| CONST COND_OP VAL 	{	$$ = concat_str(5, $1," ",$2," ",$3); }
			| VAL COND_OP CONST 	{	$$ = concat_str(5, $1," ",$2," ",$3); }
;

COND_OP: 	EQUIV 	{ $$ = "=="; 	}
			| GT	{ $$ = ">"; 	}
			| LT	{ $$ = "<"; 	}
			| LE	{ $$ = "<="; 	}
			| GE	{ $$ = ">="; 	}
;

%%

char* concat_str(int argc, ...){
	
   char * ans = NULL;
   char ** args = (char **)malloc(argc*sizeof(char *));

   int size = 0, i;

   va_list ap;
   va_start(ap, argc);
   
   for(i = 0; i < argc; i++)
   {
      args[i] = va_arg(ap, char *);
      size += strlen(args[i]);
   }

   ans = (char *)malloc((size+1)*sizeof(char)); // size+1 para el '\0'

   for(i = 0; i < argc; i++)
      sprintf(ans, "%s%s", ans, args[i]);

   va_end(ap);
   return ans;
}
	



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
math_operation(int op1, int op2, int mathOp) {

	int res;
	switch(mathOp) {
	case PLUS:
		res = op1 + op2; break;
	case MINUS:
		res = op1 - op2; break;
	case TIMES:
		res = op1 * op2; break;
	case DIVIDE:
		res = op1 / op2; break;
	}

	int size=snprintf(NULL, 0, "%d", res);
	char * str = malloc(size);
	sprintf(str, "%d", res);
	return str;
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
