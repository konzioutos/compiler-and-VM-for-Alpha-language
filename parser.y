%{
	#include <iostream>
	#include <vector>
	#include <unordered_map>
	#include <string>
	#include <algorithm>
	#include <iomanip> 
	#include <list>
	#include <stack>
	#include <assert.h>
	#include <cstring>
	#include <fstream>
	#include <map>
    using namespace std;

    int yyerror(const char* yaccProvideMessage);
    int yylex(void);

    extern int yylineno;
    extern char* yytext;
    extern FILE * yyin;

//DILWSEIS SymbolTable !!!!!!!!!!!!!!!
	int error_flag=0;
	int curr_scope=0;
	int isLocal=0;
	int max_scope=0;
	int loop_scope=0;
	int function_counter=0;
	int anonymous_functions_counter=0;
	string currentFunction="";
	vector<string> libfunctions_vector = {"print","input","objectmemberkeys","objecttotalmembers","objectcopy","totalarguments","argument","typeof","strtonum","sqrt","cos","sin"};
	vector <int> breaklist;
	vector<int>breaklist_loop_number;
	vector <int> contlist;
	vector<int>contlist_loop_number;
	int loop_number=-1;
	int temp_loop=0;
	int temp_nextquad=0;

	typedef struct variable {
		string name;
		unsigned int scope;
		unsigned int line;
	} Variable;

	typedef struct function {
		string name;
		vector<string> args;
		unsigned int scope;
		unsigned int line;
	} Function;

	enum SymbolType {
		GLOBAL, LOCALVAR, FORMAL,
		USERFUNC, LIBFUNC
	};
	typedef enum scopespace_type{ //slide 49 dialexi 9
		programvar,
		functionlocal,
		formalarg
	}scopespace_t;

	typedef enum symbol_type{ //slide 49 dialexi 9
		var_s,
		programfunc_s,
		libraryfunc_s
	}symbol_t;


	typedef struct SymbolTableEntry {
		bool isActive;
		string name;
		unsigned int scope;
		unsigned int line;
		vector<string> args;
		//string type;
		enum SymbolType type;
		scopespace_t space;//slide 49 dialexi 9
     	int offset; //slide 49 dialexi 9
		int iaddress; //slide 5 dialexi 10
		int totalLocals; //slide 7 dialexi 10
		symbol_t s_type; //slide 49 dialexi 9
		list <int> functionlistjump;
		list <int> returnList;
	} SymbolTableEntry_T;



	unordered_multimap<string,SymbolTableEntry_T*> symbol_table; // epeidei thelw parapanw apo mia emfaniseis tou key px mia global x kai mia local x
	unordered_multimap<unsigned int,SymbolTableEntry_T*> symbol_table_scopes; //diaxeirisi scope links parallila me th panw kanw insert klp
	//vector <expr*> exprList;

	map<string, int> global_vars_offset_map;
	map<string, int> local_vars_offset_map;



	//DILWSEIS QUADS !!!!!!!!!!!!!!!

	typedef enum iopcode{ //slide 37 dialexi 9
			assign, add, sub,
			mul, divv, mod,
			uminus, _and, _or,
			_not,jump, if_eq, if_noteq,
			if_lesseq, if_geatereq, if_less,
			if_greater, call,
			param, ret, getretval,
			funcstart, funcend, tablecreate,
			tablegetelem, tablesetelem,nop
 	}iopcode;

	typedef enum expr_t { //slide 17 dialexi 10
	      var_e,
	      tableitem_e,

	      programfunc_e,
	      libraryfunc_e,
	      arithexpr_e,
	      boolexpr_e,
	      assignexpr_e,
	      newtable_e,

	      constnum_e,
	      constbool_e,
	      conststring_e,
	
	      nil_e
	}expr_t; 


	typedef struct expr{ //slide 17 dialexi 10
		expr_t type;
		SymbolTableEntry_T* sym;
		expr* index;
		expr* value;
		int numConst;
		//double doubleConst;
		string strConst;
		bool boolConst;
		vector <int> breaklist;
		vector <int> contlist;
		vector <int> falselist;
		vector <int> truelist;
	}expr;


	typedef struct quad{ //slide 37 dialexi 9
			iopcode op;
			expr* result;
			expr* arg1;
			expr* arg2;
			int taddress;
			unsigned int label;
			unsigned int line;	
	} quad;

	/*struct stmt_t{
		list <int> breaklist;
		list <int> contlist;
		list <int> falselist;
		list <int> truelist;
	};*/



	//list <int> breaklist,continuelist,falselist,truelist; //mporei kai vector analoga me tis leitourgeiees sti poreia

	struct call_struct{ //slide 27-28 dialexi 10
		//vector<expr*> elist;
		list<expr*>elist;
		int method; //int anti gia char giati kanei assign sto paradeigma 0,1
		string name;
	};


	unsigned total=0;
	unsigned int currQuad=0;

	#define EXPAND_SIZE 1024
	#define CURR_SIZE (total*sizeof(quad))
	#define NEW_SIZE (EXPAND_SIZE*sizeof(quad)+CURR_SIZE)
	#define DEFAULT_LABEL -1

	vector <quad*> quads;
	vector <expr> exprs_vector;
	int tempcounter = 0;
	int programVarOffset=0;
	int functionLocalOffset=0;
	int formalArgOffset=0;
	int scopeSpaceCounter =1;

	stack <int> scopeoffsetstack; 

	struct forprefix{ //slide 17 dialexi 11
		int test;
		int enter;
	};

	int loopcounter=0;
	stack <int> loopcounterstack;

	list <expr*> exprList;
	list <expr*> indexList;
	list <int> returnlistjump;



	//Synartiseis SymbolTable !!!!!!!!!!!!!!!


	string enumToString(SymbolType type){
		switch (type)
		{
			case GLOBAL:   return "GLOBAL";
			case LOCALVAR:   return "LOCALVAR";
			case FORMAL: return "FORMAL";
			case USERFUNC: return "USERFUNC";
			case LIBFUNC: return "LIBFUNC";
		}
	}


	void insert(bool isActive ,string name, unsigned int scope , unsigned int line,SymbolType type,vector<string> arguments){
		unordered_multimap<string,SymbolTableEntry_T*> *symTable = &symbol_table;
		unordered_multimap<unsigned int,SymbolTableEntry_T*> *symTableScopes = &symbol_table_scopes;
		arguments=vector<string>{};
		SymbolTableEntry_T* newBind = new SymbolTableEntry() ;
		
		newBind->isActive = isActive;
		newBind->type = type;

		if(type==GLOBAL){
			newBind->name=name;
			newBind->scope=0;
			newBind->line=line;
			newBind->s_type=var_s;
		}
		else if(type==LOCALVAR){
			newBind->name=name;
			newBind->scope=scope;
			newBind->line=line;
			newBind->s_type=var_s;
		}
		else if( type==FORMAL){
			newBind->name=name;
			newBind->scope=scope;
			newBind->line=line;
			newBind->s_type=var_s;
		}
		else if(type==USERFUNC){
			newBind->name=name;
			newBind->scope=scope;
			newBind->line=line;
			for(string arg : arguments){
				newBind->args.push_back(arg);
			}	
			newBind->s_type=programfunc_s;
		}
		else if(type==LIBFUNC){
			newBind->name=name;
			newBind->scope=scope;
			newBind->line=line;
			for(string arg : arguments){
				newBind->args.push_back(arg);
			}	
			newBind->s_type=libraryfunc_s;
		}
		else{
			cout << "ERROR not such type!" <<endl; exit(-1);
			error_flag=1;
		}
		
		(*symTable).insert({name , newBind});
		(*symTableScopes).insert({scope ,newBind});
		
		return;

	}

	//(lookupBind->second.name==name)||(lookupBind->second.name==name)


	SymbolTableEntry_T* LookupSymbolScope(string name,unsigned int scope ,unordered_multimap<string,SymbolTableEntry_T*> symbol_table, unordered_multimap<unsigned int,SymbolTableEntry_T*> symbol_table_scopes){
		auto lookupBind = symbol_table_scopes.begin();
		
		for( lookupBind = symbol_table_scopes.begin(); lookupBind != symbol_table_scopes.end() ; lookupBind++){
			if((lookupBind->second->name==name) && lookupBind->second->isActive && (lookupBind->second->scope==scope)){
				return lookupBind->second;
			}
		}
		if(lookupBind == symbol_table_scopes.end()){
			return NULL;
		}
	}
	
	SymbolTableEntry_T* LookupSymbol(string name,unsigned int scope ,unordered_multimap<string,SymbolTableEntry_T*> symbol_table, unordered_multimap<unsigned int,SymbolTableEntry_T*> symbol_table_scopes){
		SymbolTableEntry_T* lookupBind;
		for(int scopeInitial = scope ; scopeInitial >= 0 ;scopeInitial--){
			
			if(lookupBind = LookupSymbolScope(name,scopeInitial,symbol_table,symbol_table_scopes)){
				return lookupBind;
			}
		}
		return NULL;

	}


	void Hide(unsigned int scope){
		unordered_multimap<string,SymbolTableEntry_T*> *symTable = &symbol_table;
		unordered_multimap<unsigned int,SymbolTableEntry_T*> *symTableScopes = &symbol_table_scopes;

		for(auto lookupScope = symbol_table_scopes.begin() ;lookupScope != symbol_table_scopes.end();lookupScope++){
			if((lookupScope->second->scope==scope)||(lookupScope->second->scope==scope)){
				lookupScope->second->isActive = false;
			}
			
		}
		for(auto lookupScope = symbol_table.begin() ;lookupScope != symbol_table.end();lookupScope++){
			if((lookupScope->second->scope==scope)||(lookupScope->second->scope==scope)){
				lookupScope->second->isActive = false;
			}
		}
		return ;
	}

	scopespace_t currscopespace(){ //slide 49 dialexi 9
		if(scopeSpaceCounter==1)
			return programvar;
		else if(scopeSpaceCounter%2==0)
			return formalarg;
		else
			return functionlocal;
	}

	int currscopeoffset(){ //slide 50 dialexi 9
		switch(currscopespace()){
			case programvar      : return programVarOffset;
			case functionlocal   : return functionLocalOffset;
			case formalarg       : return formalArgOffset;
			default              : assert(0);
		}
	}

	void incurrscopeoffset(){ //slide 50 dialexi 9
    	switch(currscopespace()){
			case programvar      :  ++programVarOffset; break;
			case functionlocal   :  ++functionLocalOffset; break;
			case formalarg       :  ++formalArgOffset; break;
			default              : assert(0);
		}
	}

	void enterscopespace(){ //slide 50 dialexi 9
		++scopeSpaceCounter;
	}

	void exitscopespace(){ //slide 50 dialexi 9
		assert(scopeSpaceCounter>1);
		--scopeSpaceCounter;
	}

	void resetformalargoffset(){ //slide 10 dialexi 10
		formalArgOffset=0;
	}
	
	void resetfunctionlocalsoffset(){ //slide 10 dialexi 10
		functionLocalOffset=0;
	}

	void restorecurrscopeoffset( int n){ //slide 10 dialexi 10
		switch(currscopespace()){
			case programvar      :  programVarOffset=n; break;
			case functionlocal   :  functionLocalOffset=n; break;
			case formalarg       :  formalArgOffset=n; break;
			default              : assert(0);
		}
	}


	void initialize_libfunctions(){
		//incurrscopeoffset();
		insert(true,"print",0,0,LIBFUNC,vector<string>());
		//incurrscopeoffset();
		insert(true,"input",0,0,LIBFUNC,vector<string>());
		//incurrscopeoffset();
		insert(true,"objectmemberkeys",0,0,LIBFUNC,vector<string>());
		//incurrscopeoffset();
		insert(true,"objecttotalmembers",0,0,LIBFUNC,vector<string>());
		//incurrscopeoffset();
		insert(true,"objectcopy",0,0,LIBFUNC,vector<string>());
		//incurrscopeoffset();
		insert(true,"totalarguments",0,0,LIBFUNC,vector<string>());
	//	incurrscopeoffset();
		insert(true,"argument",0,0,LIBFUNC,vector<string>());
		//incurrscopeoffset();
		insert(true,"typeof",0,0,LIBFUNC,vector<string>());
		//incurrscopeoffset();
		insert(true,"strtonum",0,0,LIBFUNC,vector<string>());
		//incurrscopeoffset();
		insert(true,"sqrt",0,0,LIBFUNC,vector<string>());
		//incurrscopeoffset();
		insert(true,"cos",0,0,LIBFUNC,vector<string>());
		//incurrscopeoffset();
		insert(true,"sin",0,0,LIBFUNC,vector<string>());
	}


	void print_output(unordered_multimap<string,SymbolTableEntry_T*> symbol_table, unordered_multimap<unsigned int,SymbolTableEntry_T*> symbol_table_scopes){
		int scope_count=0;

		for(unsigned int scopeInitial = 0 ; scopeInitial <= max_scope ;scopeInitial++){
			cout<<"-----------      Scope #"<<scopeInitial<<"     -----------"<<endl;
			for(auto lookupBind = symbol_table_scopes.begin(); lookupBind != symbol_table_scopes.end() ; lookupBind++){
				if((lookupBind->second->scope==scopeInitial)||(lookupBind->second->scope==scopeInitial)){
					if(lookupBind->second->type==GLOBAL || lookupBind->second->type==LOCALVAR || lookupBind->second->type==FORMAL){
						cout<<"\""<<lookupBind->second->name<<"\" "<<"["<<enumToString(lookupBind->second->type)<<"] "<<"(line " <<lookupBind->second->line <<") "<<"(scope " <<lookupBind->second->scope <<")"<<endl;
					}	
					if(lookupBind->second->type==USERFUNC || lookupBind->second->type==LIBFUNC){
						cout<<"\""<<lookupBind->second->name<<"\" "<<"["<<enumToString(lookupBind->second->type)<<"] "<<"(line " <<lookupBind->second->line <<") "<<"(scope " <<lookupBind->second->scope <<")"<<endl;
					}
				}
			}
			cout<<endl;
		}
	}

	SymbolTableEntry_T* insert_lvalue(bool isActive ,string name, unsigned int scope , unsigned int line,SymbolType type,vector<string> arguments){
		unordered_multimap<string,SymbolTableEntry_T*> *symTable = &symbol_table;
		unordered_multimap<unsigned int,SymbolTableEntry_T*> *symTableScopes = &symbol_table_scopes;
		arguments=vector<string>{};
		SymbolTableEntry_T* newBind =new SymbolTableEntry();
		newBind->isActive = isActive;
		newBind->type = type;
		if(type==GLOBAL){
			newBind->name=name;
			newBind->scope=0;
			newBind->line=line;
		}
		else if(type==LOCALVAR){
			newBind->name=name;
			newBind->scope=scope;
			newBind->line=line;
		}
		else if( type==FORMAL){
			newBind->name=name;
			newBind->scope=scope;
			newBind->line=line;
		}
		else if(type==USERFUNC){
			newBind->name=name;
			newBind->scope=scope;
			newBind->line=line;
			for(string arg : arguments){
				newBind->args.push_back(arg);
			}	
		}
		else if(type==LIBFUNC){
			newBind->name=name;
			newBind->scope=scope;
			newBind->line=line;
			for(string arg : arguments){
				newBind->args.push_back(arg);
			}	
		}
		else{
			cout << "ERROR not such type!" <<endl; exit(-1);
			error_flag=1;
		}
		newBind->space = currscopespace();
		newBind->offset=currscopeoffset();
		//cout<<"OFFSET!!!!!"<<newBind->offset<<endl;
		return newBind;
	}

	void insertFunctionArguments(string name,string nameOfFunction,int scope){
        unordered_multimap<string,SymbolTableEntry_T*> *symTable = &symbol_table;
		unordered_multimap<unsigned int,SymbolTableEntry_T*> *symTableScopes = &symbol_table_scopes;
        SymbolTableEntry* lookupFunction;

		lookupFunction = LookupSymbolScope(nameOfFunction,scope,symbol_table,symbol_table_scopes);
		//cout<<lookupFunction->name<<endl;
		//cout <<nameOfFunction<<endl;
	
        symbol_table.find(lookupFunction->name)->second->args.push_back(name);
		
		
		//cout<<lookupFunction->name<<symbol_table.find(lookupFunction->name)->second.args.size()<<endl;

    }


	//Synartiseis QUADS !!!!!!!!!!!!!!!

	void emit (iopcode op,expr* arg1,expr* arg2,expr* result,unsigned int label,unsigned int line){ //slide 38 dialexi 9

		quad * quad_node=new quad();

		quad_node->op=op;
		quad_node->arg1=arg1;
		quad_node->arg2=arg2;
		quad_node->result=result;
		quad_node->label=label;
		quad_node->line=line;
		
		//quads.insert(quads.begin(),quad_node);
		quads.push_back(quad_node);
		//cout<<"EMIT"<<line<<endl;
	}

	string newtempname(){ //slide 45 dialexi 9
		return "_t"+ to_string(tempcounter);
	}

	void resettemp(){ //slide 45 dialexi 9
		tempcounter = 0;
	}

	SymbolTableEntry_T* newsymbol(string name){
		unordered_multimap<string,SymbolTableEntry_T*> *symTable = &symbol_table;
		unordered_multimap<unsigned int,SymbolTableEntry_T*> *symTableScopes = &symbol_table_scopes;
		SymbolTableEntry_T* newBind =new SymbolTableEntry();
		newBind->isActive = true;
		newBind->name = name;
		newBind->line=yylineno;
		newBind->s_type = var_s;
		newBind->space =currscopespace();
		newBind->offset =currscopeoffset()+1;

		if(newBind->space==programvar){
			newBind->scope=0;
			newBind->type=GLOBAL;
		}
		else if(newBind->space==functionlocal){
			newBind->scope=curr_scope;
			newBind->type=LOCALVAR;
		}
		else if(newBind->space==formalarg){
			newBind->scope=curr_scope;
			newBind->type=FORMAL;
		}
		else{
			cout << "ERROR wrong type in newsymbol!" <<endl; exit(-1);
			error_flag=1;
		}
		incurrscopeoffset();
		(*symTable).insert({name , newBind});
		(*symTableScopes).insert({newBind->scope ,newBind});
		return newBind;
	}

	SymbolTableEntry_T* newtemp(){ //slide 45 dialexi 9
		string name=newtempname();
		SymbolTableEntry_T* sym=LookupSymbolScope(name,curr_scope,symbol_table,symbol_table_scopes);
		tempcounter++;
		if(sym==NULL){
			return newsymbol(name);
		}
		else{
			return sym;
		}
	}
 
 	int nextquadlabel(){ //slide 10 dialexi 10
		return quads.size();
	}


	void patchlabel( int quadNo, int label){ //slide 10 dialexi 10
		//assert(quadNo<currQuad);
		quads[quadNo]->label=label;
	}

	struct expr* lvalue_expr(SymbolTableEntry_T* sym){ //slide 18 dialexi 10
		struct expr* e=new expr();
		e->sym=sym;
		switch(sym->s_type){
			case var_s		   : e->type=var_e; break;
			case programfunc_s : e->type=programfunc_e; break;
			case libraryfunc_s : e->type=libraryfunc_e; break;
			default			   : assert(0);
		}
		return e;
	}

	expr* newexpr(expr_t t){ //slide 24 dialexi 10
		expr* e = new expr();
		e->type =t;
		return e;
	}

	expr* newexpr_conststring(string s){ //slide 24 dialexi 10
		expr* e = newexpr(conststring_e);
		e->type = conststring_e;
		if(s.find('"')!= string::npos){ //to kanw auto gia to lvalue DOT ID 
			e->strConst=s;

		}
		else{
			e->strConst='"'+s+'"';
		}
		return e;
	}

	expr* newexpr_constnum(double i){ //slide 29 dialexi 10
		expr* e = newexpr(constnum_e);
		e->numConst=i;
		return e;
	}

	/*expr* newexpr_constdouble(double d){
		expr* e = newexpr(constnum_e);
		e->doubleConst=d;
		return e;
	}*/

	expr* newexpr_constbool(bool b){ //slide 10 dialexi 11
		expr* e=newexpr(constbool_e);
		e->boolConst=b;
		return e;
	}

	expr* emit_iftableitem(expr* e,int line){ //slide 24 dialexi 10
		if(e->type != tableitem_e){
      		return e;
   		}
		else{
			expr* result = newexpr(var_e);
			result->sym=newtemp();
			emit(tablegetelem,e,e->index,result,DEFAULT_LABEL,line);
			return result;
		}
	}

	expr* member_item(expr* lv,string name,int line){ //slide 21 dialexi 10
		lv=emit_iftableitem(lv,line);
		expr* ti= newexpr(tableitem_e);
		ti->sym=lv->sym;
		ti->index = newexpr_conststring(name);
		return ti;
	}



	expr* make_call (expr* lv, list <expr*> reversed_elist,int line) { //opou ti kalw prepei prwta ha kanw reverse thn elist me tin reverse tis c++
		expr* func = emit_iftableitem(lv,line);
		for(list<expr*>::reverse_iterator  it = exprList.rbegin(); it != exprList.rend(); ++it){
			emit(param, *it, NULL, NULL,DEFAULT_LABEL,line);
		}
		emit(call, func,NULL, NULL,DEFAULT_LABEL,line);
		expr* result = newexpr(var_e);
		result->sym = newtemp();
		emit(getretval, NULL, NULL, result,DEFAULT_LABEL,line);
		return result;
	}

	void check_arith (expr* e, const string context) { //slide 32 dialexi 10
		if ( e->type == constbool_e ||
			e->type == conststring_e ||
			e->type == nil_e ||
			e->type == newtable_e ||
			e->type == programfunc_e ||
			e->type == libraryfunc_e ||
			e->type == boolexpr_e 
		)
		cout<<"Illegal expr used in " << context << endl;
	}

//ISWS DEN XREIAZETAI KATHOLOU AUYTES OI 2 SYNARTISIS

	unsigned int istempname (string s) { //slide 37 dialexi 10
		
		return s[0] == '_';
	}
	unsigned int istempexpr (expr* e) { //slide 37 dialexi 10
		return e->sym && istempname(e->sym->name);
	}



	int nextquad(){
		//cout<<quads.size();
		return quads.size();
	}
 
	
	void printQuads(){
		ofstream output;
  		output.open ("quads.txt");
		vector <quad*>::iterator it;
		int i=0;
		output<< "quad#   "<<"opcode           "<<"result        "<<"arg1           "<<"arg2             "<<"label"<<endl;
		output<<"------------------------------------------------------------------------------------------";
		output<<endl;
		//cout<<(*quads.end())->arg1<<endl;

		for ( it = quads.begin(); it != quads.end(); it++){
			//cout<<(*it)->arg1<<endl;
			//i++;
			output<<i<<"\t";
			//output<<(*it)->op<<endl;
			if((*it)->op==assign) output<<"assign           ";
			else if((*it)->op==add) output<<"add              ";
			else if((*it)->op==sub) output<<"sub              ";
			else if((*it)->op==mul) output<<"mul              ";
			else if((*it)->op==divv) output<<"divv              ";
			else if((*it)->op==mod) output<<"mod              ";
			else if((*it)->op==uminus) output<<"uminus              ";
			else if((*it)->op==_and) output<<"and                 ";
			else if((*it)->op==_or) output<<"or                  ";
			else if((*it)->op==_not) output<<"not                 ";
			else if((*it)->op==if_eq) output<<"if_eq            ";
			else if((*it)->op==if_noteq) output<<"if_noteq            ";
			else if((*it)->op==if_lesseq) output<<"if_lesseq           ";
			else if((*it)->op==if_geatereq)output<<"if_geatereq         ";
			else if((*it)->op==if_less) output<<"if_less              ";
			else if((*it)->op==if_greater) output<<"if_greater          ";
			else if((*it)->op==jump) output<<"jump                ";
			else if((*it)->op==call) output<<"call             ";
			else if((*it)->op==param) output<<"param            ";
			else if((*it)->op==ret) output<<"ret                 ";
			else if((*it)->op==getretval) output<<"getretval        ";
			else if((*it)->op==funcstart) output<<"funcstart        ";
			else if((*it)->op==funcend) output<<"funcend          ";
			else if((*it)->op==tablecreate) output<<"tablecreate      ";
			else if((*it)->op==tablegetelem) output<<"tablegetelem     ";
			else if((*it)->op==tablesetelem) output<<"tablesetelem     ";
			else if((*it)->op==nop) output<<"nop";

			

			if((*it)->result){
				if((*it)->result->type==boolexpr_e) output<<(*it)->result->boolConst;
				else if((*it)->result->type==constnum_e) output<<(*it)->result->numConst;
				else if((*it)->result->type==constnum_e) output<<(*it)->result->numConst;
				else if((*it)->result->type==constbool_e){
					if((*it)->result->boolConst==true) output<<"true";
					else output<<"false";
				} 
				else if((*it)->result->type==conststring_e) output<<(*it)->result->strConst;
				else if((*it)->result->type==nil_e) output<<"null";
				else 
				output<<(*it)->result->sym->name;
			} 			
			output<<"\t\t";
			
			if((*it)->arg1){
				if((*it)->arg1->type==constnum_e) output<<(*it)->arg1->numConst;
				else if((*it)->arg1->type==constnum_e) output<<(*it)->arg1->numConst;
				else if((*it)->arg1->type==constbool_e){
					if((*it)->arg1->boolConst==true) output<<"true";
					else output<<"false";
				} 
				else if((*it)->arg1->type==conststring_e) output<<(*it)->arg1->strConst;
				else if((*it)->arg1->type==nil_e) output<<"null";
				else output<<(*it)->arg1->sym->name;
			} 			
			output<<"\t\t";

			if((*it)->arg2){
				if((*it)->arg2->type==constnum_e) output<<(*it)->arg2->numConst;
				else if((*it)->arg2->type==constnum_e) output<<(*it)->arg2->numConst;
				else if((*it)->arg2->type==constbool_e){
					if((*it)->arg2->boolConst==true) output<<"true";
					else output<<"false";
				} 
				else if((*it)->arg2->type==conststring_e) output<<(*it)->arg2->strConst;
				else if((*it)->arg2->type==nil_e) output<<"null";
				else output<<(*it)->arg2->sym->name;
			} 			

			output<<"\t\t";

			if((*it)->label!=-1 &&(*it)->op!=assign){
				output<<(*it)->label; //isws thelei label+1
			}

			output<<endl;
			//cout<<""<endl;
			i++;
		}
		output.close();
	}

	void patchlist(list<int> list, int label) {
		//int index=0;
		//list <int>::iterator i = list.begin();
		for (auto& i : list) {
			//int next = quads[i]->label;
			quads[i]->label = label;
			//i=next;
			
		}
	}

	void patchvector(vector<int>list, int label,vector<int>tmp_loop) {
		//int index=0;
		//list <int>::iterator i = list.begin();
		for (vector<int>::iterator it = list.begin(); it != list.end(); ++it){
			for (vector<int>::iterator it1 = tmp_loop.begin(); it1 != tmp_loop.end(); ++it1){
			//int next = quads[i]->label;
				for(quad *q : quads){
					
						quads[(*it)]->label = label;
				}
			//cout<<"794"<<quads[(*it)]->label <<endl;
			//i=next;
			}
		}
	}


	void backpatch(vector <int> list, int label) {
		for (vector<int>::iterator it = list.begin(); it != list.end(); ++it){
			quads[(*it)]->label=label;
			//cout<<quads[(*it)]->label;
		}
	}


	/*void make_stmt (stmt_t* s){
		s.breaklist.clear(); 
		s.contList.clear();
		s.falselist.clear();
		s.truelist.clear();

	}*/

	void make_stmt (expr* s){
		s->breaklist.clear(); 
		s->contlist.clear();
		//s->falselist.clear();
		//s->truelist.clear();
	}

	int newlist (int i){ 
		quads[i]->label = 0; return i; 
	}



//Phase 4

enum vmopcode{ // slide 17 dialexi 13
	assign_v,
    add_v,
    sub_v,
    mul_v,
    div_v,
    mod_v,
    uminus_v,
    and_v,
    or_v,
    not_v,
	jump_v,
    jeq_v,
    jne_v,
    jle_v,
    jge_v,
    jlt_v,
    jgt_v,
    call_v,
    pusharg_v,
    funcenter_v,
    funcexit_v,
    newtable_v,
    tablegetelem_v,
    tablesetelem_v,
    nop_v
};

enum vmarg_t { // slide 17 dialexi 13
		label_a	=0,
		global_a =1,
		formal_a =2,
		local_a	=3,
		number_a =4,
		string_a =5,
		bool_a =6,
		nil_a =7,
		userfunc_a =8,
		libfunc_a =9,
		retval_a =10,
};

struct vmarg { // slide 17 dialexi 13
		vmarg_t		type;
		unsigned	val;
};
	
struct instruction { // slide 17 dialexi 13
	vmopcode	opcode;
	vmarg		*result;
	vmarg		*arg1;
	vmarg		*arg2;
	unsigned	srcLine;
};

vector<instruction*> instructions;
	
struct userfunc { // slide 17 dialexi 13
	unsigned	address;
	unsigned	localSize;
	string		id;
};

vector<double> numConsts; // slide 17 dialexi 13
unsigned totalNumConsts=0; // slide 17 dialexi 13
vector<string> stringConsts; // slide 17 dialexi 13
unsigned totalStringConsts=0;// slide 17 dialexi 13
vector<string> namedLibFuncs;// slide 17 dialexi 13
unsigned totalNamedLibfuncs=0;// slide 17 dialexi 13
vector<userfunc> userFuncs;// slide 17 dialexi 13
unsigned totalUserFuncs=0;// slide 17 dialexi 13
stack<SymbolTableEntry*>funcstack;// slide 17 dialexi 13

extern void generate_ADD (quad *q);
extern void generate_SUB (quad *q);
extern void generate_MUL (quad *q);
extern void generate_DIV (quad *q);
extern void generate_MOD (quad *q);
extern void generate_UMINUS(quad *q);
extern void generate_NEWTABLE (quad *q);
extern void generate_TABLEGETELEM (quad *q);
extern void generate_TABLESETELEM (quad *q);
extern void generate_ASSIGN (quad *q);
extern void generate_NOP    (quad *q);
extern void generate_JUMP   (quad *q);
extern void generate_IF_EQ  (quad *q);
extern void generate_IF_NOTEQ   (quad *q);
extern void generate_IF_GREATER (quad *q);
extern void generate_IF_GREATEREQ (quad *q);
extern void generate_IF_LESS (quad *q);
extern void generate_IF_LESSEQ (quad *q);
extern void generate_AND(quad* q);
extern void generate_NOT (quad *q);
extern void generate_OR  (quad *q);
extern void generate_PARAM (quad *q);
extern void generate_CALL  (quad *q);
extern void generate_GETRETVAL (quad *q);
extern void generate_FUNCSTART (quad *q);
extern void generate_RETURN  (quad *q);
extern void generate_FUNCEND (quad *q);

typedef void (*generator_func_t)(quad *q);

generator_func_t generators[] = {
	generate_ASSIGN,
	generate_ADD,
	generate_SUB,
	generate_MUL,
	generate_DIV,
	generate_MOD,
	generate_UMINUS,
	generate_AND,
	generate_OR,
	generate_NOT,
	generate_JUMP,
	generate_IF_EQ,
	generate_IF_NOTEQ,
	generate_IF_LESSEQ,
	generate_IF_GREATEREQ,
	generate_IF_LESS,
	generate_IF_GREATER,
	generate_CALL,
	generate_PARAM,
	generate_RETURN,
	generate_GETRETVAL,
	generate_FUNCSTART,
	generate_FUNCEND,
	generate_NEWTABLE,
	generate_TABLEGETELEM,
	generate_TABLESETELEM,
	generate_NOP,
};

void generate (void) {
	for(unsigned i =0 ; i<quads.size() ;++i) {
		(*generators[quads[i]->op]) (quads[i]);
	}
}



unsigned consts_newstring(string s){ // slide 10, dialexi 14
	stringConsts.push_back(s);
	totalStringConsts++;
	return totalStringConsts;
}

unsigned consts_newnumber(double n){ // slide 10, dialexi 14
	numConsts.push_back(n);
	totalNumConsts++;
	return totalNumConsts;
}

unsigned libfuncs_newused(string s){ // slide 10, dialexi 14
	namedLibFuncs.push_back(s);
	totalNamedLibfuncs++;
	return totalNamedLibfuncs;
}

unsigned userfuncs_newfunc(SymbolTableEntry_T* sym){ // slide 10, dialexi 14
	userfunc new_userfunc;
	new_userfunc.address=sym->iaddress;
	new_userfunc.localSize=sym->totalLocals;
	new_userfunc.id=sym->name;
	userFuncs.push_back(new_userfunc);
	totalUserFuncs++;
	return totalUserFuncs;
}

void make_operand(expr* e, vmarg* arg){ // slide 10, dialexi 14
	//cout<<"e->sym->name"<<endl;
	//if(e == NULL)	return;
	//cout<<e->type<<endl;
	switch (e->type) {
		// all those bellow use a variable for storage
		case var_e:
			arg->val=e->sym->offset;
		case assignexpr_e:
			//arg->val=e->sym->offset;
		/*{
			cout<<"EDWWWWWW"<<endl;
			arg->val=e->sym->offset;
			switch(e->sym->space) {
				case programvar: arg->type = global_a; break;
				case functionlocal:	arg->type = local_a; break;
				case formalarg:	arg->type = formal_a; break;
				default: assert(0);
			}
		}
*/
		case tableitem_e:
		case arithexpr_e:
		case boolexpr_e:
		case newtable_e: {
			assert(e->sym);
			arg->val = e->sym->offset;
			//cout<<"EDWWWWWWWWWWWW"<<endl;
			switch(e->sym->space) {
				case programvar: arg->type = global_a; break;
				case functionlocal:	arg->type = local_a; break;
				case formalarg:	arg->type = formal_a; break;
				default: assert(0);
			}
			break; //from case newtable_e
		}
		
		case constbool_e: {
			arg->val = e->boolConst;
			arg->type = bool_a; 
			break;
		}
		
		case conststring_e: {
			arg->val = consts_newstring(e->strConst);
			arg->type = string_a; 
			break;
		}
		
		case constnum_e: {
			arg->val = consts_newnumber(e->numConst)-1;
			arg->type = number_a;
			break;
		}
		
		case nil_e:	{
			arg->type = nil_a;
			break;
		}
		
		case programfunc_e: {
			//cout<<e->sym->name<<endl;
			arg->type = userfunc_a;
			arg->val = userfuncs_newfunc(e->sym);
			break;
		}
		
		case libraryfunc_e: {
			arg->type = libfunc_a;
			arg->val = libfuncs_newused(e->sym->name);
			break;
		}
		default: assert(0);
	}
}

void make_numberoperand(vmarg* arg,double val){ // slide 10, dialexi 14
	arg->val=consts_newnumber(val)-1;
	arg->type=number_a;
}

void make_booloperand(vmarg* arg,unsigned val){ // slide 10, dialexi 14
	arg->val=val;
	arg->type=bool_a;
}

void make_retvaloperand(vmarg* arg){ // slide 10, dialexi 14
	arg->type=retval_a;
}

struct incomplete_jump{ // slide 10, dialexi 14
	unsigned instrNo;
	unsigned iaddress;
};

vector<incomplete_jump> ij_head; // slide 10, dialexi 14
unsigned ij_total=0;

void add_incomplete_jump(unsigned instrNo, unsigned iaddress){ // slide 10, dialexi 14
	incomplete_jump ij;
	ij.instrNo=instrNo;
	ij.iaddress=iaddress;
	ij_head.push_back(ij);
}


int nextinstructionlabel(){ // slide 17, dialexi 14
	return instructions.size();
}


void generate(vmopcode op, quad *q){ // slide 17, dialexi 14
	instruction *t= new instruction();
	t->opcode=op;
	t->srcLine=nextinstructionlabel();
	t->arg1 = new vmarg();
	make_operand(q->arg1, t->arg1);
	if(op==assign_v||op==newtable_v){
		t->arg2=NULL;
	}
	else{
		t->arg2 = new vmarg();
		make_operand(q->arg2, t->arg2);
	}
	if(op==newtable_v){
		t->result=NULL;
	}
	else{
		t->result = new vmarg();// an den douleuei to vazw panw apo to arg1
		make_operand(q->result, t->result);	
	}
	//cout<<e->type<<endl;
	instructions.push_back(t); //emit
	//q->taddress=nextinstructionlabel();
}

void generate_ADD(quad *q) {
	generate(add_v,q);
} 
void generate_SUB(quad *q) {
	generate(sub_v,q);
}
void generate_MUL(quad *q) {
	generate(mul_v,q);
}
void generate_DIV(quad *q) {
	generate(div_v,q);
}
void generate_MOD(quad *q) {
	generate(mod_v,q);
}
void generate_UMINUS(quad *q) {
	q->arg2=newexpr_constnum(-1); // gia na ginei to uminus vazw sto 2o arg to -1 gia pollaplasiamo
	generate(mul_v,q);
}
void generate_NEWTABLE(quad* q){
	//cout<<"1173"<<endl;
  generate(newtable_v, q);
}
void generate_TABLEGETELEM(quad* q){
	//cout<<"1177"<<endl;
  generate(tablegetelem_v, q);
}
void generate_TABLESETELEM(quad* q){
	//cout<<"1181"<<endl;
  generate(tablesetelem_v, q);
}
void generate_ASSIGN(quad* q){
  	generate(assign_v, q);
}
void generate_NOP (quad *q)				{ // slide 18, dialexi 14
	instruction *t = new instruction(); 
	t->opcode=nop_v;  
	t->srcLine=nextinstructionlabel(); 
	instructions.push_back(t);
}

void generate_relational(vmopcode op , quad *q){ // slide 18, dialexi 14
	instruction *t= new instruction();
	t->opcode=op;
	if(op==jump_v){
		t->arg1 = NULL;
	}
	else{
		
		t->arg1 = new vmarg();
		make_operand(q->arg1, t->arg1);
	}
	if(op==jump_v)
		t->arg2 = NULL;
	else{
		t->arg2 = new vmarg();
		make_operand(q->arg2, t->arg2);
	}
	t->result = new vmarg();
	t->result->type=label_a;
	t->srcLine=nextinstructionlabel();

	if(q->label<quads.size()){ 
		//cout<<"1222---->> generate_relational--->>"<<endl;
		t->result->val = 	q->label;
	}
	else{
		//cout<<"1226---->> generate_relational else"<<endl;
		add_incomplete_jump(nextinstructionlabel(),q->label);
	} 
	//cout<<"1229---------->>>>>>>>>>>>>>>>"<<t->result->val<<endl;
	instructions.push_back(t);
	q->taddress=nextinstructionlabel();
}

void generate_JUMP (quad *q) { 
	generate_relational(jump_v, q); 
} 
void generate_IF_EQ(quad *q) {
	generate_relational(jeq_v,  q);
}
void generate_IF_NOTEQ(quad *q)	    {
	generate_relational(jne_v,  q);
}
void generate_IF_GREATER(quad *q)   {
	generate_relational(jgt_v,  q);
}
void generate_IF_GREATEREQ(quad *q) {
	generate_relational(jge_v,  q);
}
void generate_IF_LESS (quad *q)     {
	generate_relational(jlt_v,  q);
}
void generate_IF_LESSEQ (quad *q) {
	generate_relational(jle_v,  q);
}
void generate_AND(quad *q){

}
void generate_NOT(quad *q){

}
void generate_OR(quad *q){

}

void generate_PARAM(quad *q){ // slide 23, dialexi 14
	q->taddress=nextinstructionlabel();
	instruction *t= new instruction();
	t->arg1= new vmarg();
	make_operand(q->arg1,t->arg1);
	t->opcode=pusharg_v;
	instructions.push_back(t);
}

void generate_CALL(quad *q){ // slide 23, dialexi 14
	q->taddress=nextinstructionlabel();
	instruction *t= new instruction();
	t->arg1= new vmarg();
	make_operand(q->arg1,t->arg1);
	t->opcode=call_v;
	instructions.push_back(t);

}

void generate_GETRETVAL(quad *q){ // slide 23, dialexi 14
	q->taddress=nextinstructionlabel();
	instruction *t= new instruction();
	t->result = new vmarg();
	make_operand(q->result, t->result);
	t->arg1= new vmarg();
	make_retvaloperand(t->arg1);
	t->opcode=assign_v;
	t->result->val++;
	instructions.push_back(t);
}

void generate_FUNCSTART(quad *q){ // slide 25, dialexi 14
	SymbolTableEntry* f=q->result->sym;
	f->iaddress=nextinstructionlabel();
	q->taddress=nextinstructionlabel();
	instruction *t = new instruction();
	t->opcode = funcenter_v;
	t->result = new vmarg();
	//t->result->val = userfuncs_newfunc(f);
	funcstack.push(f);
	make_operand(q->result, t->result);
	t->result->val--;// mporei na min xreiazetai h na einai lathos
	instructions.push_back(t);
}

void generate_RETURN(quad *q) { // slide 25, dialexi 14
	instruction *t = new instruction();
	SymbolTableEntry* f;
	q->taddress=nextinstructionlabel();
	t->opcode = assign_v;
	t->result = new vmarg();
	make_retvaloperand(t->result);
	t->arg1 = new vmarg();
	make_operand(q->arg1, t->arg1);
	instructions.push_back(t);
	f=funcstack.top();
	f->functionlistjump.insert(f->functionlistjump.begin(),nextinstructionlabel());
	// isws na thelei kai to jump opws sth dialexi
}

void generate_FUNCEND(quad *q){ // slide 25, dialexi 14
	SymbolTableEntry* f =funcstack.top();
	funcstack.pop();
	for(list<int>::iterator it = f->functionlistjump.begin(); it!=f->functionlistjump.end();++it){
		instructions[(*it)]->result->val=nextinstructionlabel()+1;
	}
	q->taddress=nextinstructionlabel();
	instruction *t = new instruction();
	t->opcode = funcexit_v;
	t->result = new vmarg();
	make_operand(q->result, t->result);
	//t->result->val--;// mporei na min xreiazetai h na einai lathos
	instructions.push_back(t);
}



void create_binary_file(){
	int MagicNumber = 340200501;
	ofstream binary_output("binary.abc", ios::out | ios::binary);
	if(!binary_output){
		cout << "Cannot open file!" << endl;
      	return;
	}
	binary_output<<"MagicNumber: "<<MagicNumber<<endl;
	binary_output<<"GlobalVars: "<<programVarOffset<<endl;
	binary_output<<"NumsArray "<<"( "<<totalNumConsts<<" ):"<<endl;
	if(totalNumConsts!=0){
		for(int i=0;i<numConsts.size(); i++){
			binary_output<<setw(10);
			binary_output<<i<<": "<<numConsts[i]<<endl;
		}
	}
	binary_output<<"StringsArray "<<"( "<<totalStringConsts<<" ):"<<endl;
	if(totalStringConsts!=0){
		for(int i=0;i<stringConsts.size(); i++){
			binary_output<<setw(10);
			binary_output<<i<<": "<<stringConsts[i].size()-2<<", "<<stringConsts[i]<<endl;
		}
	}
	binary_output<<"LibFuncsArray "<<"( "<<totalNamedLibfuncs<<" ):"<<endl;
	if(totalNamedLibfuncs!=0){
		for(int i=0;i<namedLibFuncs.size(); i++){
			binary_output<<setw(10);
			binary_output<<i<<": "<<namedLibFuncs[i]<<endl;
		}
	}
	binary_output<<"UserFuncsArray "<<"( "<<totalUserFuncs<<" ):"<<endl;
	if(totalUserFuncs!=0){
		for(int i=0;i<userFuncs.size(); i++){
			binary_output<<setw(10);
			binary_output<<i<<": { "<<userFuncs[i].address<<", "<<userFuncs[i].localSize<<", "<<userFuncs[i].id<<" }"<<endl;
		}
	}
	binary_output<<"Code "<<"( "<<instructions.size()<<" ):"<<endl;
	if(instructions.size()!=0){
		for(int i=0;i<instructions.size(); i++){
			binary_output<<setw(10);
			binary_output<<"opcode: "<<instructions[i]->opcode<<endl;
			if(instructions[i]->result!=NULL){
				binary_output<<setw(15);
				binary_output<<"result:"<<endl;
				binary_output<<setw(20);
				binary_output<<"type: "<<instructions[i]->result->type<<endl;
				binary_output<<setw(20);
				binary_output<<"val: "<<instructions[i]->result->val<<endl;
			}
			if(instructions[i]->arg1!=NULL){
				binary_output<<setw(15);
				binary_output<<"arg1:"<<endl;
				binary_output<<setw(20);
				binary_output<<"type: "<<instructions[i]->arg1->type<<endl;
				binary_output<<setw(20);
				binary_output<<"val: "<<instructions[i]->arg1->val<<endl;
			}
			if(instructions[i]->arg2!=NULL){
				binary_output<<setw(15);
				binary_output<<"arg2:"<<endl;
				binary_output<<setw(20);
				binary_output<<"type: "<<instructions[i]->arg2->type<<endl;
				binary_output<<setw(20);
				binary_output<<"val: "<<instructions[i]->arg2->val<<endl;
			}
			binary_output<<endl;
		}
	}
}



%}
%locations
%define parse.error verbose
%start program

%union
{
	int intval;
    double doubleval;
    char* stringVal;
	struct SymbolTableEntry* symbolTableValue;
	struct expr* expressionValue;
	struct call_struct* callValue;
	struct forprefix* forprefixValue;
	//stmt_t* stmtValue;
}

%token <intval> INT
%token <doubleval> DOUBLE
%token <stringVal> ID
%token <stringVal> STRING


%token IF
%token ELSE 
%token WHILE 
%token FOR 
%token FUNCTION 
%token RETURN
%token BREAK 
%token CONTINUE
%token AND
%token NOT
%token OR
%token LOCAL
%token TRUE
%token FALSE
%token <stringVal> NIL
%token EQUAL
%token NOT_EQUAL
%token INCREMENT_OPERATOR
%token DECREMENT_OPERATOR
%token GREATER_EQUAL
%token LESS_EQUAL
%token DOUBLE_DOT
%token SCOPE_RESOLUTION_OPERATOR
%token UNDEFINED_TOKEN
%token ASSIGN
%token PLUS
%token MINUS
%token MULTIPLY
%token DIVIDE
%token PERCENT
%token GREATER
%token LESS
%token OPEN_CURLY_BRACKET
%token CLOSING_CURLY_BRACKET
%token OPEN_BRACKET
%token CLOSING_BRACKET
%token SEMICOLON
%token COMMA
%token COLON
%token DOT


%right			ASSIGN
%left			OR
%left			AND
%nonassoc		EQUAL NOT_EQUAL
%nonassoc		GREATER GREATER_EQUAL LESS LESS_EQUAL 
%left			PLUS MINUS
%left			MULTIPLY DIVIDE PERCENT		
%right 			NOT INCREMENT_OPERATOR DECREMENT_OPERATOR UMINUS
%left 			DOT DOUBLE_DOT
%left 			OPEN_BRACKET CLOSING_BRACKET
%left 			OPEN_PARENTHESIS CLOSING_PARENTHESIS

%type <expressionValue> expr
%type <expressionValue> lvalue
%type <expressionValue> assignexpr
%type <expressionValue> term
%type <symbolTableValue> funcprefix
%type <symbolTableValue> funcdef
%type <expressionValue> primary
%type <expressionValue> member
%type <expressionValue> call
%type <expressionValue> objectdef
%type <expressionValue> const
%type <callValue> methodcall
%type <callValue> callsuffix
%type <callValue> normcall
%type <expressionValue> elist
%type <expressionValue> elist2
%type <expressionValue> indexed
%type <expressionValue> indexedelem2
%type <expressionValue> indexedelem
%type <stringVal> funcname
%type <intval> funcbody
%type <intval> ifprefix
%type <intval> elseprefix
%type <intval> whilestart
%type <intval> whilecond
%type <expressionValue> stmt
%type <expressionValue> stmts
%type <intval> N
%type <intval> M
%type <forprefixValue> forprefix
%type <expressionValue> loopstmt



%%

program: 	stmts {} //handles many lines
			;

stmts:		stmts stmt {resettemp(); }
			| {
				resettemp();
				/*
				//$1->breaklist=mergelist($1->breaklist,$2->breaklist);
                //$1->contlist=mergelist($1->contlist,$2->contlist);
				expr *tmp=$1;
				tmp->breaklist.insert(tmp->breaklist.end(),$2->breaklist.begin(),$2->breaklist.end());
				tmp->contlist.insert($1->contlist.end(),$2->contlist.begin(),$2->contlist.end());
				$$->breaklist=tmp->breaklist;
				$$->contlist=tmp->contlist; */
			}
			;

stmt:		expr SEMICOLON {
				//resettemp();
			}
			|ifstmt {;}
			|whilestmt {;}
			|forstmt {;}
			|returnstmt {;}
			|BREAK SEMICOLON
				{
					if(curr_scope==0){
						cout<<"ERROR in line: "<<yylineno<<" break statement in scope 0"<<endl;
						error_flag=1;
					}
					//cout<<loopcounter<<endl;
					if(loopcounter==0){
						cout<<"ERROR in line: "<<yylineno<<" break statement not within loop"<<endl;
						error_flag=1;

					}
					else{
						//make_stmt(&$1);
						/*
						$$->breaklist.clear(); 
						$$->contlist.clear();
						$$->falselist.clear();
						$$->truelist.clear(); */
						//newlist()
						//quads[nextquad()]->label = 0;
						
						breaklist_loop_number.insert(breaklist_loop_number.begin(),loopcounter);
						loop_number=loopcounter;
						breaklist.insert(breaklist.begin(),nextquad()); //slide 23 dialexi 11
						emit(jump,NULL,NULL,NULL,DEFAULT_LABEL,yylineno);
					}
				}
			|CONTINUE SEMICOLON 
				{
					if(curr_scope==0){
						cout<<"ERROR: in line: "<<yylineno<<" continue statement not within a loop"<<endl;
						error_flag=1;
					}
					if(loopcounter==0){
						cout<<"ERROR in line: "<<yylineno<<" continue statement not within loop"<<endl;
						error_flag=1;

					}else{

					
						/*if(function_counter==0){
							cout<<"ERROR in line: "<<yylineno<<" continue statement not within loop"<<endl;

						}*/
						//make_stmt(&$1);
						/*$$->breaklist.clear(); 
						$$->contlist.clear();
						$$->falselist.clear();
						$$->truelist.clear();*/
						//newlist()
						//quads[nextquad()]->label = 0;
						contlist_loop_number.insert(contlist_loop_number.begin(),loopcounter);
						contlist.insert(contlist.begin(),nextquad()); //slide 23 dialexi 11
						emit(jump,NULL,NULL,NULL,DEFAULT_LABEL,yylineno);
					}
				}
			|block {;}
			|funcdef {;}
			|SEMICOLON{
				//resettemp();
			}
			;

expr:		assignexpr{;}
			|expr PLUS expr { //slide 5 dialexi 11
				check_arith($1,"+"); //prepei na ginei kai autos o elegxos opws leei to slide
				check_arith($3,"+");
				$$=newexpr(arithexpr_e);
				$$->sym=newtemp();
				emit(add,$1,$3,$$,DEFAULT_LABEL,yylineno);
			}
			|expr MINUS expr {			//slide 5 dialexi 11	
				check_arith($1,"-"); //prepei na ginei kai aytos elegxos opws leei to slide
				check_arith($3,"-");
				$$=newexpr(arithexpr_e);
				$$->sym=newtemp();
				emit(sub,$1,$3,$$,DEFAULT_LABEL,yylineno);
			}
			|expr MULTIPLY expr { //slide 5 dialexi 11
				check_arith($1,"*"); //prepei na ginei kai autos elegxos opws leei to slide
				check_arith($3,"*");
				$$=newexpr(arithexpr_e);
				$$->sym=newtemp();
				emit(mul,$1,$3,$$,DEFAULT_LABEL,yylineno);
			}
			|expr DIVIDE expr { //slide 5 dialexi 11
				check_arith($1,"/"); //prepei na ginei kai autos elegxos opws leei to slide
				check_arith($3,"/");
				$$=newexpr(arithexpr_e);
				$$->sym=newtemp();
				emit(divv,$1,$3,$$,DEFAULT_LABEL,yylineno);
			}
			|expr PERCENT expr { //slide 5 dialexi 11
				check_arith($1,"%"); //prepei na ginei kai autos elegxos opws leei to slide
				check_arith($3,"%");
				$$=newexpr(arithexpr_e);
				$$->sym=newtemp();
				emit(mod,$1,$3,$$,DEFAULT_LABEL,yylineno);
			}
			|expr GREATER expr {
				$$=newexpr(boolexpr_e);
				$$->sym=newtemp();
				$$->truelist.clear();
				$$->truelist.insert($$->truelist.begin(),nextquad());  //slide 37 front4(makelist)
				//quads[nextquad()+1]->label = 0;
				$$->falselist.clear();
				$$->falselist.insert($$->falselist.begin(),nextquad()+1); //slide 37 front4(makelist)
				emit(if_greater,$1,$3,NULL,nextquad()+1,yylineno); //slide 6 dialexi 11
				emit(jump,NULL,NULL,NULL,nextquad()+1,yylineno);

			}
			|expr GREATER_EQUAL expr {
				$$=newexpr(boolexpr_e);
				$$->sym=newtemp();
				//quads[nextquad()]->label = 0;
				$$->truelist.clear();
				$$->truelist.insert($$->truelist.begin(),nextquad());  //slide 37 front4(makelist)
				//quads[nextquad()+1]->label = 0;
				$$->falselist.clear();
				$$->falselist.insert($$->falselist.begin(),nextquad()+1); //slide 37 front4(makelist)
				emit(if_geatereq,$1,$3,NULL,nextquad()+1,yylineno); //slide 6 dialexi 11
				emit(jump,NULL,NULL,NULL,nextquad()+1,yylineno);
			}
			|expr LESS expr {
				$$=newexpr(boolexpr_e);
				$$->sym=newtemp();
				//quads[nextquad()]->label = 0;
				$$->truelist.clear();
				$$->truelist.insert($$->truelist.begin(),nextquad());  //slide 37 front4(makelist)
				//quads[nextquad()+1]->label = 0;
				$$->falselist.clear();
				$$->falselist.insert($$->falselist.begin(),nextquad()+1); //slide 37 front4(makelist)
				emit(if_less,$1,$3,NULL,nextquad()+1,yylineno); //slide 6 dialexi 11
				emit(jump,NULL,NULL,NULL,nextquad()+1,yylineno);
			}
			|expr LESS_EQUAL expr {
				$$=newexpr(boolexpr_e);
				$$->sym=newtemp();
				//quads[nextquad()]->label = 0;
				$$->truelist.clear();
				$$->truelist.insert($$->truelist.begin(),nextquad());  //slide 37 front4(makelist)
				//quads[nextquad()+1]->label = 0;
				$$->falselist.clear();
				$$->falselist.insert($$->falselist.begin(),nextquad()+1); //slide 37 front4(makelist)
				emit(if_lesseq,$1,$3,NULL,nextquad()+1,yylineno); //slide 6 dialexi 11
				emit(jump,NULL,NULL,NULL,nextquad()+1,yylineno);
			}
			|expr EQUAL expr {
				bool flag=false;

				expr* t1=newexpr(boolexpr_e);
				t1->sym=newtemp();


				if($1->truelist.empty()){
					t1=$1;
				}
				else{ 
					int i=0;

					backpatch($1->truelist,nextquad());

					// an den douleuei to emit 

					

					quad * quad_node=new quad();

					quad_node->op=assign;
					quad_node->arg1=newexpr_constbool(true);
					quad_node->arg2=NULL;
					quad_node->result=t1;
					quad_node->label=DEFAULT_LABEL;
					quad_node->line=yylineno;

					quads.insert(quads.begin()+nextquad(),quad_node);
					
					

					/*
					i=$3+1;
					while(i<nextquad()){
						cout<<"I AM HERE*************"<<endl;
						quads[i]->line=i;
						quads[i]->label+=1;
						i++;
					}*/

					// an den douleuei to emit 

					//emit(assign,newexpr_constbool(true),NULL,NULL,-1,yylineno);

					quad * quad_node1=new quad();

					quad_node1->op=jump;
					//quad_node1->arg1=NULL;
					//quad_node1->arg2=NULL;
					//quad_node1->result=NULL;
					quad_node1->label=nextquad()+2;
					quad_node1->line=yylineno;

					quads.insert(quads.begin()+nextquad(),quad_node1);

					//emit(jump,NULL,NULL,NULL,nextquad()+2,yylineno);

					/*
					i=$3+2;
					while(i<nextquad()){
						cout<<"I AM HERE!!!!!!!!!!!!!!!!!!!!!!!!!!1"<<endl;
						quads[i]->line=i;
						quads[i]->label+=1;
						i++;
					}*/

					backpatch($1->falselist,nextquad());
					
					// an den douleuei to emit 

					

					quad * quad_node2=new quad();

					quad_node2->op=assign;
					quad_node2->arg1=newexpr_constbool(false);
					quad_node2->arg2=NULL;
					quad_node2->result=t1;
					quad_node2->label=DEFAULT_LABEL;
					quad_node2->line=yylineno;

					quads.insert(quads.begin()+nextquad(),quad_node2);

					
					//emit(assign,newexpr_constbool(false),NULL,NULL,-1,yylineno);
					/*
					i=$3+3;
					while(i<nextquad()){
						cout<<"I AM HERE%%%%%%%%%%%%"<<endl;
						quads[i]->line=i;
						quads[i]->label+=1;
						i++;
					}*/
					flag=true;
				}

				expr* t2=newexpr(boolexpr_e);
				t2->sym=newtemp();

				if($3->truelist.empty()){
					t2=$3;
				}
				else{ 
					int i=0;
					if(flag==false){
						backpatch($3->truelist,nextquad());
					}
					else{
						for (vector<int>::iterator it = $3->truelist.begin(); it != $3->truelist.end(); ++it){
							quads[(*it)+3]->label=nextquad();
						}
					}
					emit(assign,newexpr_constbool(true),NULL,t2,DEFAULT_LABEL,yylineno);
					emit(jump,NULL,NULL,NULL,nextquad()+2,yylineno);
					if(flag==false){
						backpatch($3->falselist,nextquad());
					}
					else{
						for (vector<int>::iterator it = $3->falselist.begin(); it != $3->falselist.end(); ++it){
							quads[(*it)+3]->label=nextquad();
						}
					}
					emit(assign,newexpr_constbool(false),NULL,t2,DEFAULT_LABEL,yylineno);
				}

				$$=newexpr(boolexpr_e);
				$$->sym=newtemp();
				
				$$->truelist.insert($$->truelist.begin(),nextquad()); //slide 37 front4(makelist)
				$$->falselist.insert($$->falselist.begin(),nextquad()+1); //slide 37 front4(makelist)
				emit(if_eq,t1,t2,NULL,nextquad()+1,yylineno); //slide 6 dialexi 11
				emit(jump,NULL,NULL,NULL,nextquad()+1,yylineno);
			}
			|expr NOT_EQUAL expr {
								bool flag=false;

				expr* t1=newexpr(boolexpr_e);
				t1->sym=newtemp();


				if($1->truelist.empty()){
					t1=$1;
				}
				else{ 
					int i=0;

					backpatch($1->truelist,nextquad());

					// an den douleuei to emit 

					

					quad * quad_node=new quad();

					quad_node->op=assign;
					quad_node->arg1=newexpr_constbool(true);
					quad_node->arg2=NULL;
					quad_node->result=t1;
					quad_node->label=DEFAULT_LABEL;
					quad_node->line=yylineno;

					quads.insert(quads.begin()+nextquad(),quad_node);
					
					

					/*
					i=$3+1;
					while(i<nextquad()){
						cout<<"I AM HERE*************"<<endl;
						quads[i]->line=i;
						quads[i]->label+=1;
						i++;
					}*/

					// an den douleuei to emit 

					//emit(assign,newexpr_constbool(true),NULL,NULL,-1,yylineno);

					quad * quad_node1=new quad();

					quad_node1->op=jump;
					//quad_node1->arg1=NULL;
					//quad_node1->arg2=NULL;
					//quad_node1->result=NULL;
					quad_node1->label=nextquad()+2;
					quad_node1->line=yylineno;

					quads.insert(quads.begin()+nextquad(),quad_node1);

					//emit(jump,NULL,NULL,NULL,nextquad()+2,yylineno);

					/*
					i=$3+2;
					while(i<nextquad()){
						cout<<"I AM HERE!!!!!!!!!!!!!!!!!!!!!!!!!!1"<<endl;
						quads[i]->line=i;
						quads[i]->label+=1;
						i++;
					}*/

					backpatch($1->falselist,nextquad());
					
					// an den douleuei to emit 

					

					quad * quad_node2=new quad();

					quad_node2->op=assign;
					quad_node2->arg1=newexpr_constbool(false);
					quad_node2->arg2=NULL;
					quad_node2->result=t1;
					quad_node2->label=DEFAULT_LABEL;
					quad_node2->line=yylineno;

					quads.insert(quads.begin()+nextquad(),quad_node2);

					
					//emit(assign,newexpr_constbool(false),NULL,NULL,-1,yylineno);
					/*
					i=$3+3;
					while(i<nextquad()){
						cout<<"I AM HERE%%%%%%%%%%%%"<<endl;
						quads[i]->line=i;
						quads[i]->label+=1;
						i++;
					}*/
					flag=true;
				}

				expr* t2=newexpr(boolexpr_e);
				t2->sym=newtemp();

				if($3->truelist.empty()){
					t2=$3;
				}
				else{ 
					int i=0;
					if(flag==false){
						backpatch($3->truelist,nextquad());
					}
					else{
						for (vector<int>::iterator it = $3->truelist.begin(); it != $3->truelist.end(); ++it){
							quads[(*it)+3]->label=nextquad();
						}
					}
					emit(assign,newexpr_constbool(true),NULL,t2,DEFAULT_LABEL,yylineno);
					emit(jump,NULL,NULL,NULL,nextquad()+2,yylineno);
					if(flag==false){
						backpatch($3->falselist,nextquad());
					}
					else{
						for (vector<int>::iterator it = $3->falselist.begin(); it != $3->falselist.end(); ++it){
							quads[(*it)+3]->label=nextquad();
						}
					}
					emit(assign,newexpr_constbool(false),NULL,t2,DEFAULT_LABEL,yylineno);
				}

				$$=newexpr(boolexpr_e);
				$$->sym=newtemp();
				
				$$->truelist.insert($$->truelist.begin(),nextquad()); //slide 37 front4(makelist)
				$$->falselist.insert($$->falselist.begin(),nextquad()+1); //slide 37 front4(makelist)
				emit(if_noteq,t1,t2,NULL,nextquad()+1,yylineno); //slide 6 dialexi 11
				emit(jump,NULL,NULL,NULL,nextquad()+1,yylineno);		
			}
			|expr AND {
				temp_nextquad=0;
				if($1->truelist.empty()){
					$1->truelist.insert($1->truelist.begin(),nextquad()); //slide 37 front4
					$1->falselist.insert($1->falselist.begin(),nextquad()+1);//slide 37 front4
					emit(if_eq,$1,newexpr_constbool(true),NULL,nextquad()+1,yylineno); //slide 37 front4
					emit(jump,NULL,NULL,NULL,nextquad()+1,yylineno);
					//$3=nextquad();
					temp_nextquad=nextquad();
				}
			} M expr {
				
				//backpatch($1->truelist, $3);
				if(temp_nextquad==$4){
					if(!$5->truelist.empty()){
					backpatch($5->truelist,$1->truelist.front()); //slide 37 front4
					
				}
				}
				
				if($5->truelist.empty()){
					$5->truelist.insert($5->truelist.begin(),nextquad()); //slide 37 front4
					$5->falselist.insert($5->falselist.begin(),nextquad()+1); //slide 37 front4
					emit(if_eq,$5,newexpr_constbool(true),NULL,nextquad()+1,yylineno); //slide 6 dialexi 11, exw ant gia and,or,not quads -> if_eq if_noeq opws to okeanos
					emit(jump,NULL,NULL,NULL,nextquad()+1,yylineno);
				}
				backpatch($1->truelist, $4);//slide 37 front4
				$$->truelist=$5->truelist; //slide 37 front4
				
				
				expr *tmp=$1;
				tmp->falselist.insert(tmp->falselist.end(),$5->falselist.begin(),$5->falselist.end());//slide 37 front4(merge)
				$$->falselist=tmp->falselist;

			}
			|expr OR {
				if($1->truelist.empty()){
					$1->truelist.insert($1->truelist.begin(),nextquad());
					$1->falselist.insert($1->falselist.begin(),nextquad()+1);
					emit(if_eq,$1,newexpr_constbool(true),NULL,DEFAULT_LABEL,yylineno);
					emit(jump,NULL,NULL,NULL,DEFAULT_LABEL,yylineno);
					if($1->truelist.empty()){
						cout<<"emit in lines 1991-92 not working!!"<<endl;
						assert(NULL);
					}

				} 
				} M expr {
				
				backpatch($1->falselist,$4);

				if($5->truelist.empty()){
					$5->truelist.insert($5->truelist.begin(),nextquad());
					$5->falselist.insert($5->falselist.begin(),nextquad()+1);
					emit(if_eq,$5,newexpr_constbool(true),NULL,DEFAULT_LABEL,yylineno);
					emit(jump,NULL,NULL,NULL,DEFAULT_LABEL,yylineno);
				}
				
			//slide 37 front4
				expr *tmp=$1;
				tmp->truelist.insert(tmp->truelist.end(),$5->truelist.begin(),$5->truelist.end()); //slide 37 front4(merge)
				$$->truelist=tmp->truelist;
				$$->falselist=$5->falselist;

			}
			|term{$$=$1;}
			;

term:		OPEN_PARENTHESIS expr CLOSING_PARENTHESIS   { //slide 32 dialexi 10
				$$=$2;
			}
			|MINUS expr %prec UMINUS { //slide 32 dialexi 10
				check_arith($2,"- expr");
				$$=newexpr(arithexpr_e);
				$$->sym=istempexpr($2) ? $2->sym : newtemp();
                emit(uminus,$2,NULL,$$,DEFAULT_LABEL,yylineno);				
			}
			|NOT expr {
				expr* e = new expr();
				if($2->truelist.empty()){
					$2->truelist.insert($2->truelist.begin(),nextquad()); //slide 37 front4
					$2->falselist.insert($2->falselist.begin(),nextquad()+1); //slide 37 front4
					emit(if_eq,$2,newexpr_constbool(true),NULL,nextquad()+1,yylineno); //eixa ifnoteq
					emit(jump,NULL,NULL,NULL,nextquad()+1,yylineno);
				}
				e=$2;
				$$=newexpr(boolexpr_e); //slide 32 dialexi 10
				$$->sym=newtemp();
				//$$->truelist=$2->falselist;
				$2->falselist.swap($2->truelist);
				//$$->falselist=$2->truelist;
				$$=$2;
			}
			|INCREMENT_OPERATOR	lvalue 
				{
					check_arith($2,"++lvalue"); //slide 34 dialexi 10
					if($2->type==tableitem_e){
						$$=emit_iftableitem($2,yylineno);
						emit(add,$$,newexpr_constnum(1),$$,DEFAULT_LABEL,yylineno);
						emit(tablesetelem,$2,$2->index,$$,DEFAULT_LABEL,yylineno);
					}
					else if($2->type==USERFUNC || $2->type==LIBFUNC){
						cout<<"ERROR:function cannot make operation line "<< yylineno<< endl;
						error_flag=1;
					}
					else{
						emit(add,$2,newexpr_constnum(1),$2,DEFAULT_LABEL,yylineno);
						$$=newexpr(arithexpr_e);
						$$->sym= newtemp();
						emit(assign,$2,NULL,$$,DEFAULT_LABEL,yylineno);
					}
				}
			|lvalue INCREMENT_OPERATOR 
				{

					check_arith($1,"lvalue++"); //slide 34 dialexi 10
					$$ = newexpr(var_e);
					$$->sym = newtemp();
					if ($1->type == tableitem_e) {
						expr* val = emit_iftableitem($1,yylineno);
						emit(assign, val, NULL, $$,DEFAULT_LABEL,yylineno);
						emit(add, val, newexpr_constnum(1), val,DEFAULT_LABEL,yylineno);
						emit(tablesetelem, $1, $1->index, val,DEFAULT_LABEL,yylineno);
					}				
					else if($1->type==USERFUNC || $1->type==LIBFUNC){
						cout<<"ERROR:function cannot make operation line "<< yylineno<< endl;
						error_flag=1;
					}
					else{
						emit(assign,$1,NULL,$$,DEFAULT_LABEL,yylineno);
						emit(add, $1, newexpr_constnum(1), $1,DEFAULT_LABEL,yylineno);
					}
					
				}
			|DECREMENT_OPERATOR lvalue
				{
					check_arith($2,"--lvalue"); //slide 34 dialexi 10
					if($2->type==tableitem_e){
						$$=emit_iftableitem($2,yylineno);
						emit(sub,$$,newexpr_constnum(1),$$,DEFAULT_LABEL,yylineno);
						emit(tablesetelem,$2,$2->index,$$,DEFAULT_LABEL,yylineno);
					}
					else if($2->type==USERFUNC || $2->type==LIBFUNC){
						cout<<"ERROR:function cannot make operation line "<< yylineno<< endl;
						error_flag=1;
					}
					else{
						emit(sub,$2,newexpr_constnum(1),$2,DEFAULT_LABEL,yylineno);
						$$=newexpr(arithexpr_e);
						$$->sym= newtemp();
						emit(assign,$2,NULL,$$,DEFAULT_LABEL,yylineno);
					}
				}
			|lvalue DECREMENT_OPERATOR 
				{
					check_arith($1,"lvalue--"); //slide 34 dialexi 10
					$$ = newexpr(var_e);
					$$->sym = newtemp();
					if ($1->type == tableitem_e) {
						expr* val = emit_iftableitem($1,yylineno);
						emit(assign, val, NULL, $$,DEFAULT_LABEL,yylineno);
						emit(sub, val, newexpr_constnum(1), val,DEFAULT_LABEL,yylineno);
						emit(tablesetelem,$1, $1->index, val,DEFAULT_LABEL,yylineno);
					}				
					else if($1->type==USERFUNC || $1->type==LIBFUNC){
						cout<<"ERROR:function cannot make operation line "<< yylineno<< endl;
						error_flag=1;
					}
					else{
						emit(assign,$1,NULL,$$,DEFAULT_LABEL,yylineno);
						emit(sub, $1, newexpr_constnum(1), $1,DEFAULT_LABEL,yylineno);
					}
				}
			|primary{
				$$=$1;
			}
			;

assignexpr: lvalue ASSIGN expr {
				if($1==NULL){
					}
					else if($1->type==USERFUNC || $1->type==LIBFUNC){
						cout<<"Errot at line "<<yylineno<<": cannot assign in function "<< $1->sym->name<<endl;
						error_flag=1;
				}
				if($1->type==tableitem_e){ //slide 23 dialexi 10
					//cout<<"EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"<<endl;
					emit(tablesetelem,$1->index,$3,$1, DEFAULT_LABEL,yylineno);
					$$ = emit_iftableitem($1,yylineno);
					$$->type=assignexpr_e;
				}
				else{ 
					if($3->truelist.empty()) {
						
					}
					else if(!$3->truelist.empty()) {
						
							backpatch($3->truelist,nextquad());
							emit(assign,newexpr_constbool(true),NULL,$1,DEFAULT_LABEL,yylineno);
							emit(jump,NULL,NULL,NULL,nextquad()+2,yylineno);
							backpatch($3->falselist,nextquad());
							emit(assign,newexpr_constbool(false),NULL,$1,DEFAULT_LABEL,yylineno);
					}
					//backpatch($3->falselist,nextquad());
					$$=$3;
					emit(assign,$3,NULL,$1,-1,yylineno);
					$$=newexpr(assignexpr_e);
					$$->sym=newtemp(); 
					emit(assign,$1,NULL,$$,-1,yylineno);

				}
				
				
			}
			;

primary:	lvalue {$$=emit_iftableitem($1,yylineno);} //slide 22 dialexi 10
			|call {$$=$1;}
			|objectdef {$$=$1;}
			|OPEN_PARENTHESIS funcdef CLOSING_PARENTHESIS   {//slide 31 dialexi 10
				$$=newexpr(programfunc_e);
				$$->sym=$2; 

			}
			|const {$$=$1;}
			;

lvalue:		ID 
				{	
					//cout<<"2185"<<endl;
					bool tokenFoundNotFound = true, redefined = false;
					//cout << "-----------------------"<<endl;
					for(auto lookupToken = symbol_table.begin() ;lookupToken != symbol_table.end();lookupToken++){
						//elegxos gia redifinition
						//cout<<"2189"<<endl;
						//cout << "ID: "<<yytext<<endl;
						//cout << "looking for "<< lookupToken->second->name <<"    line:"<<yylineno<<endl;
						if( lookupToken->second->type != USERFUNC && lookupToken->second->type != LIBFUNC){
							if(lookupToken->second->name == yytext){
								
								tokenFoundNotFound=false;
								if(lookupToken->second->scope!=0 && function_counter!=0 && (curr_scope-lookupToken->second->scope>1)&& loop_scope==0){ //prosthesa auto gia to provlima sto error3
									//cout<<lookupToken->second->scope<<function_counter<<curr_scope-lookupToken->second->scope<<endl;
									cout << "ERROR: at line: "<<yylineno<< " Cannot access "<<yytext<<" inside function "<<endl;	
									error_flag=1;
								}
								if(lookupToken->second->type==FORMAL && lookupToken->second->isActive){
									//tokenFoundNotFound=true; //prosthesa auto gia to provlima sto simple test, An uparxei provlima me ta formal kai local edw isws den thellei true
									SymbolTableEntry_T* val=insert_lvalue(true,yytext,lookupToken->second->scope,lookupToken->second->line,FORMAL,vector<string>());
									val->space=formalarg;
									val->offset=formalArgOffset;
									$$=lvalue_expr(val);
									//cout << "found: "<<lookupToken->second->name<<endl;
									break;
								}
								if(lookupToken->second->type==FORMAL && !lookupToken->second->isActive){
									tokenFoundNotFound=true; //prosthesa auto gia to provlima sto simple test, An uparxei provlima me ta formal kai local edw isws den thellei true
									
								}
								if(lookupToken->second->scope != 0 &&  lookupToken->second->scope < curr_scope && lookupToken->second->isActive==true){
									if(isLocal==1 &&loop_scope!=1){
										
										cout << "ERROR: at line: "<<yylineno<< " Local variable "<<yytext<< " out of scope."<<endl;	
										error_flag=1;										
									}
									if(lookupToken->second->type==FORMAL){
										cout << "ERROR: at line: "<<yylineno<< " Cannot access formal  "<<yytext<< " inside function out of his scope."<<endl;
										error_flag=1;
									}

									//tha kanoume assign to neo value
								}
								//cout<<"2219"<<endl;
								//cout<<"tokenFound:"<< tokenFoundNotFound<<endl;
								//cout<< lookupToken->second->scope<<endl;
								if(tokenFoundNotFound == false && lookupToken->second->scope==0){
									//cout<<lookupToken->second->scope<<endl;
									//cout<<currscopespace()<<endl;
									//cout<<currscopeoffset()<<endl;
									//cout<<lookupToken->second->offset<<endl;
									SymbolTableEntry_T* val=insert_lvalue(true,yytext,lookupToken->second->scope,lookupToken->second->line,GLOBAL,vector<string>());
									val->offset=global_vars_offset_map.find(yytext)->second;									
									$$ = lvalue_expr(val);
									redefined = true;
								}
								else if (tokenFoundNotFound == false && lookupToken->second->scope>0){
									//cout<<lookupToken->second->scope<<endl;
									//cout<<currscopespace()<<endl;
									//cout<<currscopeoffset()<<endl;
									//cout<<lookupToken->second->offset<<endl;
									SymbolTableEntry_T* val=insert_lvalue(true,yytext,lookupToken->second->scope,lookupToken->second->line,LOCALVAR,vector<string>());
									//val->offset=lookupToken->second->offset+1;
									val->offset=local_vars_offset_map.find(yytext)->second;
									$$ = lvalue_expr(val);
									redefined = true;
								}
							}else
								tokenFoundNotFound = true;
						}
						else{
							//cout <<lookupToken->second.type<<"lala"<<endl;
							//cout << "test" << endl;
							if((lookupToken->second->scope==curr_scope ||lookupToken->second->scope<curr_scope) && lookupToken->second->type == USERFUNC){
								if(lookupToken->second->name == yytext){
									SymbolTableEntry_T* val=insert_lvalue(true,yytext,curr_scope,yylineno,USERFUNC,vector<string>());
									$$->sym=val;
									tokenFoundNotFound=false;
									//cout << "ERROR: at line: "<<yylineno<< " Cannot use a variable as function "<<endl;
									$$ = lvalue_expr(lookupToken->second);
									
								}
							}else if(lookupToken->second->type == LIBFUNC){
								if(lookupToken->second->name == yytext){
									$$->sym=lookupToken->second;// amfivolia gia to an douleuei 
									tokenFoundNotFound = false;
									//cout << "libfunc: " << lookupToken->second->name<<endl;
									//cout << "libfunc: " << lookupToken->second->type<<endl;
									$$ = lvalue_expr(lookupToken->second);
									break;
								}
							}
						}
					}
				
					if(tokenFoundNotFound && !redefined){ //eixe tokenFound edw
						SymbolTableEntry* val;
						incurrscopeoffset();
						if(curr_scope==0){
							//cout<<"2248"<<endl;
							insert(true,yytext,curr_scope,yylineno,GLOBAL,vector<string>());
							val=insert_lvalue(true,yytext,curr_scope,yylineno,GLOBAL,vector<string>());
							//cout<<"2269->>>>>>>>>>"<<val->offset<<endl;
							global_vars_offset_map.insert({ yytext, val->offset });
						}
						else if (!tokenFoundNotFound && !redefined){
							//cout<<"2272"<<endl;
							insert(true,yytext,curr_scope,yylineno,LOCALVAR,vector<string>());
							val=insert_lvalue(true,yytext,curr_scope,yylineno,LOCALVAR,vector<string>());
							local_vars_offset_map.insert({ yytext, val->offset });
							

						}
						//val->space=currscopespace();
						//val->offset=currscopeoffset();
						//cout<<"2260"<<endl;
						$$=lvalue_expr(val);
					}
					//print_output(symbol_table,symbol_table_scopes);
				}
			|LOCAL ID 
				{
					isLocal=0;
					if(curr_scope!=0){
						if(!LookupSymbolScope(yytext,curr_scope,symbol_table,symbol_table_scopes)){
							if (find(libfunctions_vector.begin(), libfunctions_vector.end(), yytext) != libfunctions_vector.end()){
								cout<<"ERROR: Cannot shadow library function"<<endl;
								error_flag=1;
								//$$=NULL;
							}
							else{
								incurrscopeoffset();
								insert(true,yytext,curr_scope,yylineno,LOCALVAR,vector<string>());
								isLocal=1;
								SymbolTableEntry* val=insert_lvalue(true,yytext,curr_scope,yylineno,LOCALVAR,vector<string>());
								//val->space=currscopespace();
								//val->offset=currscopeoffset();								
								$$=lvalue_expr(val);
								
							}
						}
					}
					else{
						if(!LookupSymbolScope(yytext,curr_scope,symbol_table,symbol_table_scopes)){
							//cout<<"INSIDE IFFFFF LOCAL ID&&&&&&&&&&&&&&&&&&&&"<<endl;
							if (find(libfunctions_vector.begin(), libfunctions_vector.end(), yytext) != libfunctions_vector.end()){
								cout<<"ERROR: Cannot shadow library function"<<endl;
								error_flag=1;
								//$$=NULL;
							}
							else{
								isLocal=1;
								incurrscopeoffset();
								//cout<<"INSIDE ELSE LOCAL ID&&&&&&&&&&&&&&&&&&&&"<<endl;
								insert(true,yytext,curr_scope,yylineno,GLOBAL,vector<string>());
								//cout<<"AFTER INSERT IN LOCAL ID !!!!!!!!!!"<<endl;
								//print_output(symbol_table,symbol_table_scopes);
								SymbolTableEntry* val=insert_lvalue(true,yytext,curr_scope,yylineno,GLOBAL,vector<string>());
								//val->space=currscopespace();
								//val->offset=currscopeoffset();
								$$=lvalue_expr(val);
															
							}
						}
					}
				}			
			|SCOPE_RESOLUTION_OPERATOR ID 
				{
					if(LookupSymbolScope(yytext,0,symbol_table,symbol_table_scopes)){
						SymbolTableEntry* val=insert_lvalue(true,yytext,curr_scope,yylineno,GLOBAL,vector<string>());
						val->space=programvar;
						//val->offset=programVarOffset;
						$$=lvalue_expr(val);					
					}
					else{
						cout<<"ERROR: There is not a global variable with this name"<<endl;
						error_flag=1;
						$$ = NULL;
					}
				}
			|member {$$ = $1;}
			;

member: 	lvalue DOT ID {
							$$=member_item($1,$3,yylineno); 
						}
			| lvalue OPEN_BRACKET expr CLOSING_BRACKET { //slide 22 dialexi 10
					$1 =emit_iftableitem($1,yylineno); 
					$$=newexpr(tableitem_e);
					$$->sym=$1->sym; 
					$$->index=$3;
			}
			| call DOT ID{;}
			| call OPEN_BRACKET expr CLOSING_BRACKET{;}

call:		call OPEN_PARENTHESIS elist CLOSING_PARENTHESIS   { //slide 27 dialexi 10
				exprList.reverse();
				$$=make_call($1,exprList,yylineno);
			}
			|lvalue callsuffix {
				//exprList.clear();
				$1 = emit_iftableitem($1,yylineno); //slide 28 dialexi 10
				if($2->method) { //slide 28 dialexi 10
					expr* t = $1;
					$1 = emit_iftableitem(member_item(t,$2->name,yylineno),yylineno);
					$2->elist.push_front(t);//mporei na thelei push back an prepei na mpei sto telos an einai reversed
				}
				$2->elist.reverse();
				$$ = make_call($1,$2->elist,yylineno);
			}
			|OPEN_PARENTHESIS funcdef CLOSING_PARENTHESIS OPEN_PARENTHESIS elist CLOSING_PARENTHESIS   { //slide 27 dialexi 10
				expr* func = newexpr(programfunc_e);
				func->sym = $2;
				exprList.reverse();
				$$ = make_call(func,exprList,yylineno);
			}
			;

callsuffix:	normcall { //slide 28 dialexi 10
				 $$= $1;
			}
			|methodcall { //slide 28 dialexi 10
				$$= $1;
			}
			;

normcall:	OPEN_PARENTHESIS{ //slide 28 dialexi 10
				exprList.clear();
			}
			elist CLOSING_PARENTHESIS   {
				struct call_struct* method_call=new call_struct();
				method_call->elist=exprList;
				method_call->method=0;
				method_call->name="";
				$$=method_call;				
			}
			;

methodcall:	DOUBLE_DOT ID OPEN_PARENTHESIS{ //slide 27 dialexi 10
					exprList.clear();
				} elist CLOSING_PARENTHESIS   {
				struct call_struct *method_call=new call_struct();
				method_call->elist=exprList;
				method_call->method=1;
				method_call->name=$2;
				$$=method_call;
			}
			;

elist:		expr{ }  
			elist2 {
				if($1->truelist.empty()){
					$$=$1;
				}
				else{
					expr *e=lvalue_expr(newtemp());
					backpatch($1->truelist,nextquad());
					emit(assign,newexpr_constbool(true),NULL,e,DEFAULT_LABEL,yylineno);
					emit(jump,NULL,NULL,NULL,nextquad()+2,yylineno);
					backpatch($1->falselist,nextquad());
					emit(assign,newexpr_constbool(false),NULL,e,DEFAULT_LABEL,yylineno);
					$1=e;	
				}
				//exprList.push_back($1);
				exprList.push_front($1);
			}
			| { $$=NULL;}
			;

elist2:		COMMA expr{}elist2{
				if($2->truelist.empty()){
					$$=$2;
				}
				else{
					expr *e=lvalue_expr(newtemp());
					backpatch($2->truelist,nextquad());
					emit(assign,newexpr_constbool(true),NULL,e,DEFAULT_LABEL,yylineno);
					emit(jump,NULL,NULL,NULL,nextquad()+2,yylineno);
					backpatch($2->falselist,nextquad());
					emit(assign,newexpr_constbool(false),NULL,e,DEFAULT_LABEL,yylineno);
					$2=e;	
				} 
				//exprList.push_back($2);
				exprList.push_front($2);
			}
			| { $$=NULL;}
			;
/*clearIndexList:	|{
						indexList.clear();
			    	} */
objectdef: 	 OPEN_BRACKET{
					exprList.clear();
				} elist CLOSING_BRACKET	{ //slide 29 dialexi 10
				int i=0;
				expr* t=newexpr(newtable_e);
                t->sym =newtemp();
                emit(tablecreate,t,NULL,NULL,DEFAULT_LABEL,yylineno);
				for (list<expr*>::iterator it = exprList.begin(); it != exprList.end(); ++it){
                    emit(tablesetelem,newexpr_constnum(i),*it,t,DEFAULT_LABEL,yylineno);	
					i++;
				}
				$$=t;
			}
			| OPEN_BRACKET{
				indexList.clear(); 
			} indexed CLOSING_BRACKET { //slide 30 dialexi 10
				expr* t=newexpr(newtable_e);
                t->sym =newtemp();
                 emit(tablecreate,t,NULL,NULL,DEFAULT_LABEL,yylineno);
				for (list<expr*>::iterator it = indexList.begin(); it != indexList.end(); ++it){
                    emit(tablesetelem,(*it)->index,(*it)->value,t,DEFAULT_LABEL,yylineno);	//anti gia $2 isws na prepei na parw to elist se ekeino to index ara na doulepsw me vector			
				}
				indexList.clear();
				$$=t;
			}
			;

indexed:	indexedelem indexedelem2 {
				indexList.push_front($1);
				$$=$1;
			}
			;

indexedelem2:	COMMA indexedelem  indexedelem2{
					indexList.push_front($2);
					$$=$2;
				}
				|	{$$=NULL;}					
				;

indexedelem:  OPEN_CURLY_BRACKET expr COLON expr CLOSING_CURLY_BRACKET  {
					//indexList.push_front($4);
					$$=$4;
                	$$->index=$2;
					$$->value=$4;
				}
			 ;

block:		 OPEN_CURLY_BRACKET  
				{
					//cout<<"I AM IN FUNCTION block"<<endl;
					curr_scope++;
					max_scope=max(max_scope,curr_scope);
				}
				stmts CLOSING_CURLY_BRACKET  
				{
					Hide(curr_scope);
					curr_scope--;
				}
				;

funcname: ID { //slide 5 dialexi 10
				$$=$1;
			 }
		   | {
			   anonymous_functions_counter++;
			   currentFunction = "$f"+to_string(anonymous_functions_counter);
			   $$=const_cast<char*>(currentFunction.c_str());
		     }
			;
		
funcprefix: FUNCTION funcname { //slide 5 dialexi 10
				incurrscopeoffset();
				insert(true,$2,curr_scope,yylineno,USERFUNC,vector<string>());
				SymbolTableEntry* val=insert_lvalue(true,$2,curr_scope,yylineno,USERFUNC,vector<string>());
				val->s_type=programfunc_s;
				val->iaddress=nextquadlabel()+1;//epeidi einai 0 arxika, mporei na min xreiazetai omws
				$$=val;
				$$->functionlistjump.push_front(nextquad());
				emit(jump,NULL,NULL,NULL,DEFAULT_LABEL,nextquad());
				emit(funcstart,NULL,NULL,lvalue_expr(val),DEFAULT_LABEL,yylineno);
				
				scopeoffsetstack.push(currscopeoffset());
				enterscopespace();
             	resetformalargoffset();
			}
			;

funcargs: OPEN_PARENTHESIS //slide 6 dialexi 10
			{
				enterscopespace();
				
				curr_scope++;
				max_scope=max(max_scope,curr_scope);
			} 
			idlist CLOSING_PARENTHESIS {
				curr_scope--;
				//enterscopespace();
				resetfunctionlocalsoffset();
			}
			;

funcbody: block {							//slide 6 dialexi 10
					$$=currscopeoffset();
					exitscopespace();
					//function_counter--;
				}
				;

funcdef: funcprefix funcargs { //slide 7 dialexi 10
					loopcounterstack.push(loopcounter);
					loopcounter=0;
					function_counter++;
				} 
				funcbody
				{
					
					exitscopespace();
					$1->totalLocals=$4;
					int offset=scopeoffsetstack.top();
					scopeoffsetstack.pop();	
					restorecurrscopeoffset(offset);
					$$=$1;
					emit(funcend,NULL,NULL,lvalue_expr($$),DEFAULT_LABEL,yylineno);
					patchlist(returnlistjump,nextquad()-1);
					patchlist($1->functionlistjump,nextquad());
					if(!returnlistjump.empty())
						returnlistjump.pop_front();
					//$1->functionlistjump.pop_front();
					loopcounter=loopcounterstack.top();
					loopcounterstack.pop();
					function_counter--;
				}
				;

const:		INT {
				$$=newexpr(constnum_e);
				$$->numConst=$1;
			}
			|DOUBLE {
				$$=newexpr_constnum($1);
			}
			|STRING {
				$$=newexpr_conststring($1);
			}
			|NIL {
				$$=newexpr(nil_e);
				$$->strConst=$1;
			}
			|TRUE {
				$$=newexpr_constbool(true);
			}
			|FALSE {
				$$=newexpr_constbool(false);
			}
			;

idlist:		ID 
            {
                //cout<<"I AM IN FUNCTION IDLIST"<<endl;

                if(function_counter){
                    
                    insertFunctionArguments(yytext,currentFunction,curr_scope-1);
                }
                SymbolTableEntry_T* formalArgumentFound = LookupSymbol(yytext,curr_scope,symbol_table,symbol_table_scopes);
                if(formalArgumentFound){
                    if(formalArgumentFound->name == yytext && formalArgumentFound->isActive==true && formalArgumentFound->scope==curr_scope ){
                        cout<<"ERROR: Redeclaration of formal argument "<< yytext <<endl;
						error_flag=1;
                    }else if (formalArgumentFound->type == LIBFUNC){
                        cout<<"ERROR: Argument "<< yytext << " shadows libary function" <<endl;
						error_flag=1;
                    }
					else if(formalArgumentFound->scope!=curr_scope){
						//cout<<"AAAAAAAAAAAAAAA"<<endl;
						incurrscopeoffset();
						insert(true,yytext,curr_scope,yylineno,FORMAL,vector<string>());
						
					}
                }else{
					//cout<<"AAAAAEEEEEEEEEEEEEEEEEEAAAAAAAAAA"<<endl;
                   // cout << "test"<<endl;
				   	incurrscopeoffset();
                    insert(true,yytext,curr_scope,yylineno,FORMAL,vector<string>());
					
                }
            }
			multiidlist{;}
			| {;}
            ;

multiidlist:  COMMA ID 
            {
                //cout<<"I AM IN FUNCTION IDLIST"<<endl;

                if(function_counter){

                    insertFunctionArguments(yytext,currentFunction,curr_scope-1);
                }
                //cout << "lalaqla\n";
                SymbolTableEntry_T* formalArgumentFound = LookupSymbol(yytext,curr_scope,symbol_table,symbol_table_scopes);

                if(formalArgumentFound){
                    if(formalArgumentFound->name == yytext && formalArgumentFound->type== FORMAL ){
                        cout<<"ERROR: Redeclaration of formal argument "<< yytext <<endl;
						error_flag=1;
                    }else if (formalArgumentFound->type == LIBFUNC){
                        cout<<"ERROR: Argument "<< yytext << " shadows libary function" <<endl;
						error_flag=1;
                    }
				else if(formalArgumentFound->scope!=curr_scope){
						//cout<<"AAAAAAAAAAAAAAA"<<endl;
						incurrscopeoffset();
						insert(true,yytext,curr_scope,yylineno,FORMAL,vector<string>());
					}
                }else{
                   // cout << "test"<<endl;
				   incurrscopeoffset();
                    insert(true,yytext,curr_scope,yylineno,FORMAL,vector<string>());
                }
            }
			multiidlist{;}
			| {;}
            ;

ifprefix:	IF OPEN_PARENTHESIS expr CLOSING_PARENTHESIS {
				expr *e = $3;
				if($3->truelist.empty()){

				}
				else{
					e = lvalue_expr(newtemp());
					backpatch($3->truelist,nextquad());
					emit(assign,newexpr_constbool(true),NULL,e,DEFAULT_LABEL,yylineno);
					emit(jump,NULL,NULL,NULL,nextquad()+2,yylineno);	
					backpatch($3->falselist,nextquad());
					emit(assign,newexpr_constbool(false),NULL,e,DEFAULT_LABEL,yylineno);
					
				}

				emit(if_eq,e,newexpr_constbool(true),NULL,nextquad()+2,yylineno); //slide 10 dialexi 11
				$$=nextquad();
				emit(jump,NULL,NULL,NULL,0,yylineno);
			}
			;

ifstmt:		ifprefix stmt {
				patchlabel($1,nextquad()); //slide 10 dialexi 11
			}
			| ifprefix stmt elseprefix stmt{ //slide 12 dialexi 11
				patchlabel($1,$3+1);
				patchlabel($3,nextquad());
			}
			;

elseprefix: ELSE{ //slide 12 dialexi 11
				$$=nextquad();
				emit(jump,NULL,NULL,NULL,0,yylineno);
			}
			;

loopstart:	{++loopcounter;} //slide 22 dialexi 11
          	;

loopend:	{//--loopcounter;
			} //slide 22 dialexi 11
          	;

loopstmt:	loopstart  stmt loopend{$$=$2;}


whilestart: WHILE{
				$$=nextquad(); //slide 15 dialexi 11
			}
			;

whilecond: OPEN_PARENTHESIS{
				loop_scope++;
			} 
			expr CLOSING_PARENTHESIS{

				if($3->truelist.empty()){ 

				}
				else{
					backpatch($3->truelist,nextquad());
					emit(assign,newexpr_constbool(true),NULL,lvalue_expr(newtemp()),DEFAULT_LABEL,yylineno);
					emit(jump,NULL,NULL,NULL,nextquad()+2,yylineno);
					backpatch($3->falselist,nextquad());
					emit(assign,newexpr_constbool(false),NULL,lvalue_expr(newtemp()),DEFAULT_LABEL,yylineno);
				}

				emit(if_eq,$3,newexpr_constbool(true),NULL,nextquad()+2,yylineno); //slide 15 dialexi 11
				$$=nextquad();
				emit(jump,NULL,NULL,NULL,0,yylineno);
				//loopcounter++;
			}
			;
				
whilestmt:	whilestart whilecond loopstmt{ //slide 22 dialexi 11
				loop_scope--;
				int f=0;
				emit(jump,NULL,NULL,NULL,$1,yylineno); //slide 15 dialexi 11
				patchlabel($2,nextquad());
				patchvector(breaklist,nextquad()+1,breaklist_loop_number);
				patchvector(contlist,$1,contlist_loop_number);				
				//loopcounter++;
				while(loopcounter!=-1){
					if(loopcounter>1){
					//patchvector(breaklist,nextquad()DEFAULT_LABEL,breaklist_loop_number);
					//patchvector(contlist,$1+2,contlist_loop_number);
					f=1;
					loopcounter--;
					
					}
					if(loopcounter>0){
						patchvector(breaklist,nextquad(),breaklist_loop_number);
						patchvector(contlist,$1,contlist_loop_number);
						f=1;
						loopcounter--;
					}
					//--loopcounter;
					if(loopcounter==0){
						patchvector(breaklist,nextquad(),breaklist_loop_number);
						patchvector(contlist,$1,contlist_loop_number);
						//loopcounter++;
						breaklist.clear();
						contlist.clear();
						loopcounter--;
					}
				}
			}
			;


N:			{
				$$=nextquad(); //dialexi 11 slide 17
				emit(jump,NULL,NULL,NULL,0,yylineno);
			}
			;

M:			{
				$$=nextquad(); //slide 37 front4
			}

forprefix:	FOR OPEN_PARENTHESIS  
			{
				loop_scope++;
			} elist SEMICOLON M expr SEMICOLON{
				if($7->truelist.empty()){

				}
				else{
					backpatch($7->truelist,nextquad());
					emit(assign,newexpr_constbool(true),NULL,lvalue_expr(newtemp()),DEFAULT_LABEL,yylineno);
					emit(jump,NULL,NULL,NULL,nextquad()+2,yylineno);
					backpatch($7->falselist,nextquad());
					emit(assign,newexpr_constbool(false),NULL,lvalue_expr(newtemp()),DEFAULT_LABEL,yylineno);
						
				}
				$$= new forprefix();
				$$->test=$6; //slide 17 dialexi 11
				$$->enter=nextquad();
                emit(if_eq,$7,newexpr_constbool(true),NULL,0,yylineno);				
			}
			;
				
forstmt:	forprefix N elist CLOSING_PARENTHESIS{
					exprList.clear();
				}
				N loopstmt {loop_scope--;} N{
					patchlabel($1->enter,$6+1); //slide 17 dialexi 11
					patchlabel($2,nextquad());
					patchlabel($6,$1->test); 
					patchlabel($9,$2+1);
					patchvector(breaklist,nextquad()+1,breaklist_loop_number);
					patchvector(contlist,$2+1,contlist_loop_number);
					while(loopcounter!=-1){
						if(loopcounter>1){
							//patchvector(breaklist,nextquad()-1,breaklist_loop_number);
							//patchvector(contlist,$1+2,contlist_loop_number);

							loopcounter--;
						}
						if(loopcounter>0){
							patchvector(breaklist,nextquad(),breaklist_loop_number);
							patchvector(contlist,$2+1,contlist_loop_number);
							loopcounter--;
						}
						//--loopcounter;
						if(loopcounter==0){
							patchvector(breaklist,nextquad(),breaklist_loop_number);
							patchvector(contlist,$2+1,contlist_loop_number);
							//loopcounter++;
							breaklist.clear();
							contlist.clear();
							loopcounter--;
						}
					}	
					loopcounter++;
				}
			;



				
returnstmt:	RETURN expr SEMICOLON
				{
					if(function_counter==0){
						cout<<"ERROR in line: "<<yylineno<<" return statement outside of function"<<endl;
						error_flag=1;
					}
					else if($2->truelist.empty()){

					}
					else{
						backpatch($2->truelist,nextquad());
						emit(assign,newexpr_constbool(true),NULL,lvalue_expr(newtemp()),DEFAULT_LABEL,yylineno);
						emit(jump,NULL,NULL,NULL,nextquad()+2,yylineno);
						backpatch($2->falselist,nextquad());
						emit(assign,newexpr_constbool(false),NULL,lvalue_expr(newtemp()),DEFAULT_LABEL,yylineno);
							
					}
					emit(ret,$2,NULL,NULL,DEFAULT_LABEL,yylineno); //slide 25 dialexi 11
					returnlistjump.push_front(nextquad());
					emit(jump,NULL,NULL,NULL,DEFAULT_LABEL,yylineno);

				}
			|RETURN SEMICOLON 
				{
					if(function_counter==0){
						cout<<"ERROR in line: "<<yylineno<<" return statement outside of function"<<endl;
						error_flag=1;
					}
					else {emit(ret,NULL,NULL,NULL,DEFAULT_LABEL,yylineno);
					returnlistjump.push_front(nextquad()); //slide 25 dialexi 11
					emit(jump,NULL,NULL,NULL,0,yylineno);
					}
				}
			;


%%

int yyerror (char const* yaccProvidedMessage)
{
	fprintf(stderr,"%s: at line %d, before token: '%s'\n", yaccProvidedMessage, yylineno, yytext);
    fprintf(stderr,"INPUT NOT VALID\n");
}

int main(int argc, char **argv) {
	extern int yydebug;
    yydebug = 0;

	if(argc > 1){
		if(!(yyin = fopen(argv[1],"r"))){
			fprintf(stderr,"Cannot read file: %s\n",argv[1]);
			return 1;
		}
	}
	else
		yyin = stdin;
	initialize_libfunctions();
	//cout<<"BEFORE yyparse"<<endl;
	yyparse();
	//cout<<"after yyparse"<<endl;
	if(error_flag==0){
		print_output(symbol_table,symbol_table_scopes);
		printQuads();
	}
	generate();
	create_binary_file();

	/*auto lookupBind = symbol_table.begin();
	int result=0;	
	for( lookupBind = symbol_table.begin(); lookupBind != symbol_table.end() ; lookupBind++){
		if((lookupBind->second->space==programvar) && lookupBind->second->s_type==var_s ){
			result++;
			cout<<"fsfs"<<endl;
		}
	}
*/
	//cout<<"globalVars: "<<to_string(programVarOffset)<<endl;
	return 0;
}