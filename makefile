all:
	flex --outfile=lex.cpp lex.l
	bison --yacc -t -d -v --defines --output=parser.cpp parser.y
	g++ -w -std=c++11 -o compiler lex.cpp parser.cpp
	g++ -std=c++11 -o virtualMachine virtual.cpp
clean:
	rm -rf compiler lex lex.cpp parser.cpp parser.hpp parser.output quads.txt virtualMachine binary.abc