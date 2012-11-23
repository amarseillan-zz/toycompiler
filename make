#!/bin/bash
bison -yd ./src/parser.y -v
flex ./src/scanner.l 
gcc -o  c_converter lex.yy.c y.tab.c -ly -ll -g -lm
rm y.tab.* lex.yy.c y.output
