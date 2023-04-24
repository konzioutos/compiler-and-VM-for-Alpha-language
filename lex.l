%{
    #include <iostream>
    #include <string>
    #include <vector>
    #include <list>
    #include <stack>
    #include <queue>
    #include "parser.hpp"
    using namespace std;


    typedef struct alpha_token_t {
        unsigned int numline;
        unsigned int numToken;
        string content;
        string type;
    }token;
    
    typedef struct CommentFromTo{
        int start_line;
        int end_line;
    }commentLines;

    typedef struct comments_tokens{
        unsigned int numline;
        unsigned int numToken;
        unsigned int start;
        unsigned int end;
        string type;
    }com_tok;


    string str = "";
    int line_counter = 0;
    int com_counter = 0;
    int koupes = 1;
    int nested_comment= 0;
    list <token> tokens_list;
    stack <commentLines> linesOfComments;
    queue <com_tok> commentsQueue;
%}

%option noyywrap
%option yylineno

if if
else else
while while
for for
function function
return return
break break
continue continue
and and
not not
or or
local local
true true
false false
nil nil

assign =
plus \+
minus -
multiply \*
divide \/
percent %
equal ==
not_equal !=
increcement_operator \++
decreacement_operator --
greater >
less <
greater_equal >=
less_equal <=
int [0-9]+
double [0-9]+\.[0-9]+
open_curly_backet \{
closing_curly_bracket \}
open_bracket \[
closing_bracket \]
open_parenthesis \(
closing_parenthesis \)
semicolon ;
comma ,
colon :
scope_resolution_operator ::
dot \.
double_dot \.\.
id [a-zA-Z]+[a-zA-Z_0-9]*
line_comment \/\/.*
newline "\n"
tab "\t"
whitespace [\t' '\r]*

%x STR
%x COMMENT

%%

{if} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"if","KEYWORD IF <-enumerated"});
    return IF;}
{else} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"else","KEYWORD ELSE <-enumerated"});
    return ELSE;}
{while} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"while","KEYWORD WHILE <-enumerated"});
    return WHILE;}
{for} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"for","KEYWORD FOR <-enumerated"});
    return FOR;}
{function} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"function","KEYWORD FUNCTION <-enumerated"});
    return FUNCTION;}
{return} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"return","KEYWORD RETURN <-enumerated"});
    return RETURN ;}
{break} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"break","KEYWORD BREAK <-enumerated"});
    return BREAK;}
{continue} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"continue","KEYWORD CONTINUE <-enumerated"});
    return CONTINUE;}
{and} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"and","KEYWORD AND <-enumerated"});
    return AND;}
{not} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"not","KEYWORD NOT <-enumerated"});
    return NOT;}
{or} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"or","KEYWORD OR <-enumerated"});
    return OR;}
{local} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"local","KEYWORD LOCAL <-enumerated"});
    return LOCAL;}
{true} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"true","KEYWORD TRUE <-enumerated"});
    return TRUE;}
{false} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"false","KEYWORD FALSE <-enumerated"});
    return FALSE;}
{nil} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"nil","KEYWORD NIL <-enumerated"});
    return NIL;}
{assign} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"=","OPERATOR ASSIGN <-enumerated"});
    return ASSIGN;}
{plus} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"+","OPERATOR PLUS <-enumerated"});
    return PLUS;}
{minus} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"-","OPERATOR MINUS <-enumerated"});
    return MINUS;}
{multiply} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"*","OPERATOR MULTIPLY <-enumerated"});
    return MULTIPLY;}
{divide} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"/","OPERATOR DIVIDE <-enumerated"});
    return DIVIDE;}
{percent} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"%","OPERATOR PERCENT <-enumerated"});
    return PERCENT;}
{equal} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"==","OPERATOR EQUAL <-enumerated"});
    return EQUAL;}
{not_equal} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"!=","OPERATOR NOT_EQUAL <-enumerated"});
    return NOT_EQUAL;}
{increcement_operator} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"++","OPERATOR INCREACEMENT <-enumerated"});
    return INCREMENT_OPERATOR;}
{decreacement_operator} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"--","OPERATOR DECREACEMENT <-enumerated"});
    return DECREMENT_OPERATOR;}
{greater} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,">","OPERATOR GREATER <-enumerated"});
    return GREATER;}
{less} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"<less>","OPERATOR LESS <-enumerated"});
    return LESS;}
{greater_equal} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,">=","OPERATOR GREATER_EQUAL <-enumerated"});
    return GREATER_EQUAL;}
{less_equal} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"<=","OPERATOR LESS_EQUAL <-enumerated"});
    return LESS_EQUAL;}
{int} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,yytext,"CONST_INT <-integer"});
    yylval.intval = atoi(yytext); return INT;}
{double} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,yytext,"CONST_DOUBLE <-integer"});
    yylval.doubleval = atof(yytext); return DOUBLE;}
{open_curly_backet} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"{","PUNCTUATION OPEN_CURLY_BRACKET <-enumerated"});
    return OPEN_CURLY_BRACKET;}
{closing_curly_bracket} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"}","PUNCTUATION CLOSING_CURLY_BRACKET <-enumerated"});
    return CLOSING_CURLY_BRACKET;}
{open_bracket} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"[","PUNCTUATION OPEN_BRACKET <-enumerated"});
    return OPEN_BRACKET;}
{closing_bracket} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"]","PUNCTUATION CLOSING_BRACKET <-enumerated"});
    return CLOSING_BRACKET;}
{open_parenthesis} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"(","PUNCTUATION OPEN_PARENTHESIS <-enumerated"});
    return OPEN_PARENTHESIS;}
{closing_parenthesis} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,")","PUNCTUATION CLOSING_PARENTHESIS <-enumerated"});
    return CLOSING_PARENTHESIS;}
{semicolon} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,";","PUNCTUATION SEMICOLON <-enumerated"});
    return SEMICOLON;}
{comma} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,",","PUNCTUATION COMMA <-enumerated"});
    return COMMA;}
{colon} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,":","PUNCTUATION COLON <-enumerated"});
    return COLON;}
{scope_resolution_operator} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"::","PUNCTUATION SCOPE_RESOLUTION_OPERATOR <-enumerated"});
    return SCOPE_RESOLUTION_OPERATOR;}
{dot} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,".","PUNCTUATION DOT <-enumerated"});
    return DOT;}
{double_dot} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"..","PUNCTUATION DOUBLE_DOT <-enumerated"});
    return DOUBLE_DOT;}
{id} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,yytext,"ID <-string"});
    yylval.stringVal = strdup(yytext); return ID;}
{line_comment} {tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,"\"\"","COMMENT LINE_COMMENT <-enumerated"});}
{tab} {}
{whitespace} {}
{newline} {}

\" {BEGIN(STR); str = "";}
<STR>\\t {str += '\t';}
<STR>\\n {str += '\n';}
<STR>\n {str +='\n';}
<STR>\\\" {str += '\"';}
<STR>\\\\ {str += '\\';}
<STR>[^\\\n\"]+ {str+=string(yytext);}
<STR>\\[^tn\\] {str += string(yytext); cout<<"Line "<<(unsigned int)yylineno-1 << " WARNING! Invalid espace character "<<yytext[1]<<endl;}

<STR>\" {  BEGIN(INITIAL);
                string content = "\"" + str + "\"" ;
                tokens_list.push_back({(unsigned int)yylineno, (unsigned int)tokens_list.size()+1,str,"STRING"});
                yylval.stringVal = strdup(content.c_str());
                return STRING;
                str ="";
            }
<STR>\n  {
                BEGIN(INITIAL); 
                cout << "ERROR in line " << yylineno <<" Expected string closing expression"<<endl;
            }

"/*" {nested_comment = 0;BEGIN(COMMENT);com_counter++;linesOfComments.push({(unsigned int)yylineno,(unsigned int)yylineno});}
<COMMENT>[^*]*"/*" {nested_comment=1;com_counter++;linesOfComments.push({(unsigned int)yylineno,(unsigned int)yylineno});}
<COMMENT>[^*]*  {}
<COMMENT>"*"+[^*/]* {}
<COMMENT>"*/" {
                    com_counter--;
                    linesOfComments.top().end_line=yylineno;

                    int top_comment_start=linesOfComments.top().start_line;
                    int top_comment_end=linesOfComments.top().end_line;
                    linesOfComments.pop();
                        
                    if(nested_comment == 0){
                        BEGIN(INITIAL);
                        commentsQueue.push({top_comment_start, (unsigned int)tokens_list.size()+1,top_comment_start,top_comment_end,"COMMENT BLOCK_COMMENT <- enumerated"});
                    }else{
                        commentsQueue.push({top_comment_start, (unsigned int)tokens_list.size()+1,top_comment_start,top_comment_end,"NESTED_COMMENT BLOCK_COMMENT <- enumerated"});

                        if(com_counter==1)
                            nested_comment = 0;   
                    }
                    while(!commentsQueue.empty()){
                            tokens_list.push_back({commentsQueue.front().numline,commentsQueue.front().numToken,"",commentsQueue.front().type});
                            commentsQueue.pop();
                    }
                    koupes = 1;
                } 

 
   

<<EOF>> {
            if(com_counter>0){
                cout << "ERROR in line " << linesOfComments.top().start_line <<" Expected comment closing expression"<<endl; yyterminate();
            }
            yyterminate();
        }

. { 
    tokens_list.push_back({(unsigned int)yylineno,(unsigned int)tokens_list.size()+1,yytext,"UNDEFINED TOKEN"});
    return UNDEFINED_TOKEN;
}
          

%%
