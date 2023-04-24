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
#include <cmath>
#include <math.h>

using namespace std;

#define AVM_STACKSIZE 4096

#define AVM_WIPEOUT(m) memset(&(m), 0, sizeof(m));

enum vmopcode
{ // slide 17 dialexi 13
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

enum vmarg_t // slide 17 dialexi 13
{
    label_a = 0,
    global_a = 1,
    formal_a = 2,
    local_a = 3,
    number_a = 4,
    string_a = 5,
    bool_a = 6,
    nil_a = 7,
    userfunc_a = 8,
    libfunc_a = 9,
    retval_a = 10,
};

struct vmarg // slide 17 dialexi 13
{
    vmarg_t type;
    unsigned val;
};

struct instruction // slide 17 dialexi 13
{
    vmopcode opcode;
    vmarg *result;
    vmarg *arg1;
    vmarg *arg2;
    unsigned srcLine;
};

vector<instruction *> instructions;

struct userfunc // slide 17 dialexi 13
{
    unsigned address;
    unsigned localSize;
    string id;
};

enum avm_memcell_t // slide 17 dialexi 13
{
    number_m = 0,
    string_m = 1,
    bool_m = 2,
    table_m = 3,
    userfunc_m = 4,
    libfunc_m = 5,
    nil_m = 6,
    undef_m = 7
};

struct avm_table;

struct avm_memcell // slide 21 dialexi 13
{
    avm_memcell_t type;
    double numVal; // afairesame to enum gia dieukolinsi giati sthn c++ EINAI PARANOIA h arxikopoiisi tou sto struct
    string strVal;
    bool boolVal;
    avm_table *tableVal;
    unsigned funcVal;
    string libfuncVal;
};

vector<double> numConsts;        // slide 17 dialexi 13
unsigned totalNumConsts = 0;     // slide 17 dialexi 13
vector<string> stringConsts;     // slide 17 dialexi 13
unsigned totalStringConsts = 0;  // slide 17 dialexi 13
vector<string> namedLibFuncs;    // slide 17 dialexi 13
unsigned totalNamedLibfuncs = 0; // slide 17 dialexi 13
vector<userfunc> userFuncs;      // slide 17 dialexi 13
unsigned totalUserFuncs = 0;     // slide 17 dialexi 13

int GlobalVars = 0;

avm_memcell vm_stack[AVM_STACKSIZE]; // slide 17 dialexi 13
stack<avm_memcell> avm_stack;
unsigned top, topsp;

avm_table *avm_tablenew();                                                 // slide 25 dialexi 13
void avm_tabledestroy(avm_table *t);                                       // slide 25 dialexi 13
avm_memcell *avm_tablegetelem(avm_table *t, avm_memcell *key);             // slide 25 dialexi 13
void avm_tablesetelem(avm_table *t, avm_memcell *key, avm_memcell *value); // slide 25 dialexi 13

#define AVM_TABLE_HASHSIZE 211 // slide 25 dialexi 13

#define AVM_STACKENV_SIZE 4
avm_memcell ax,
    bx, cx;
avm_memcell retval;

#define execute_add execute_arithmetic // slide 25 dialexi 15
#define execute_sub execute_arithmetic
#define execute_mul execute_arithmetic
#define execute_div execute_arithmetic
#define execute_mod execute_arithmetic

#define execute_jge execute_comparison
#define execute_jgt execute_comparison
#define execute_jle execute_comparison
#define execute_jlt execute_comparison

typedef void (*execute_func_t)(instruction *); // slide 13 dialexi 15

#define AVM_MAX_INSTRUCTIONS (unsigned)nop_v // slide 13 dialexi 15

extern void execute_assign(instruction *); // slide 13 dialexi 15

extern void execute_add(instruction *); // slide 13 dialexi 15
extern void execute_sub(instruction *);
extern void execute_mul(instruction *);
extern void execute_div(instruction *);
extern void execute_mod(instruction *);

extern void execute_uminus(instruction *);
extern void execute_and(instruction *);
extern void execute_or(instruction *);
extern void execute_not(instruction *);

extern void execute_jump(instruction *);
extern void execute_jeq(instruction *);
extern void execute_jne(instruction *);
extern void execute_jle(instruction *);
extern void execute_jge(instruction *);
extern void execute_jlt(instruction *);
extern void execute_jgt(instruction *);

extern void execute_call(instruction *);
extern void execute_pusharg(instruction *);

extern void execute_funcenter(instruction *);
extern void execute_funcexit(instruction *);

extern void execute_newtable(instruction *);
extern void execute_tablegetelem(instruction *);
extern void execute_tablesetelem(instruction *);

extern void execute_nop(instruction *);

execute_func_t executeFuncs[] = {
    // slide 14 dialexi 15
    execute_assign,
    execute_add,
    execute_sub,
    execute_mul,
    execute_div,
    execute_mod,
    execute_uminus,
    execute_and,
    execute_or,
    execute_not,
    execute_jump,
    execute_jeq,
    execute_jne,
    execute_jle,
    execute_jge,
    execute_jlt,
    execute_jgt,
    execute_call,
    execute_pusharg,
    execute_funcenter,
    execute_funcexit,
    execute_newtable,
    execute_tablegetelem,
    execute_tablesetelem,
    execute_nop,
};

unsigned executionFinished = 0; // slide 14 dialexi 15
unsigned pc = 0;
unsigned currLine = 0;
unsigned codeSize = 0;
instruction *code = (instruction *)0;

#define AVM_ENDING_PC codeSize

extern void avm_error(string format, ...);
extern string avm_tostring(avm_memcell *);
extern void avm_calllibfunc(string funcName);
extern void avm_callsaveenvironment();

#define AVM_NUMACTUALS_OFFSET 4 // slide 21 dialexi 15
#define AVM_SAVEDPC_OFFSET 3
#define AVM_SAVEDTOP_OFFSET 2
#define AVM_SAVEDTOPSP_OFFSET 1

extern userfunc *avm_getfuncinfo(unsigned address); // slide 21 dialexi 15

static void avm_initstack(); // slide 17 dialexi 13 slide

void avm_tableincrefcounter(avm_table *t);

void avm_tabledecrefcounter(avm_table *t);

void avm_tablebucketsinit(unordered_multimap<avm_memcell *, avm_memcell *> hash_table); // slide 26 dialexi 13

void memclear_string(avm_memcell *m);

void memclear_table(avm_memcell *m);

typedef void (*memclear_func_t)(avm_memcell *);

void avm_memcellclear(avm_memcell *m);

void avm_tablebucketsdestroy(unordered_multimap<avm_memcell *, avm_memcell *> hash_table);

avm_memcell *hash_lookup(unordered_multimap<avm_memcell *, avm_memcell *> hash_table, avm_memcell *key, avm_memcell_t type);

double consts_getnumber(unsigned index);

string consts_getstring(unsigned index);

string libfuncs_getused(unsigned index);

avm_memcell *avm_translate_operand(vmarg *arg, avm_memcell *reg); // slide 8 dialexi 15

void execute_cycle();

void avm_warning(char *format, ...);

void avm_assign(avm_memcell *lv, avm_memcell *rv);

void avm_dec_top();

void avm_push_envvalue(unsigned val);

unsigned avm_get_envvalue(unsigned i);

typedef void (*library_func_t)(void); // slide 22 dialexi 15

struct library_func
{
    string id;
    library_func_t addr;
};

unsigned avm_totalactuals();

avm_memcell *avm_getactual(unsigned i);

void libfunc_print(); // slide 35 front 5

void libfunc_input();

void libfunc_objectmemberkeys();

void libfunc_objecttotalmembers();

void libfunc_objectcopy();

void libfunc_argument();

void libfunc_strtonum();

void libfunc_sqrt();

void libfunc_cos();

void libfunc_sin();

void libfunc_totalarguments();

string typeStrings[] = {
    "number",
    "string",
    "bool",
    "table",
    "userfunc",
    "libfunc",
    "nil",
    "undef"};

void libfunc_typeof();

void avm_registerlibfunc(string id, library_func_t addr);

typedef string (*tostring_func_t)(avm_memcell *);

string number_tostring(avm_memcell *m);

string string_tostring(avm_memcell *m);

string bool_tostring(avm_memcell *m);

string table_tostring(avm_memcell *m);

string userfunc_tostring(avm_memcell *m);

string libfunc_tostring(avm_memcell *m);

string nil_tostring(avm_memcell *m);

string undef_tostring(avm_memcell *m);

tostring_func_t tostringFuncs[] = { // slide 23 dialexi 15
    number_tostring,
    string_tostring,
    bool_tostring,
    table_tostring,
    userfunc_tostring,
    libfunc_tostring,
    nil_tostring,
    undef_tostring};

string avm_tostring(avm_memcell *m);

typedef double (*arithmetic_func_t)(double x, double y);

double add_impl(double x, double y);

double sub_impl(double x, double y);

double mul_impl(double x, double y);

double div_impl(double x, double y);

double mod_impl(double x, double y);

arithmetic_func_t arithmeticFuncs[] = { // slide 25 dialexi 15
    add_impl,
    sub_impl,
    mul_impl,
    div_impl,
    mod_impl};

void execute_arithmetic(instruction *instr);

typedef bool (*cmp_func)(double x, double y);

bool jge_impl(double x, double y);

bool jgt_impl(double x, double y);

bool jle_impl(double x, double y);

bool jlt_impl(double x, double y);

cmp_func comparisonFuncs[] = {
    jle_impl,
    jge_impl,
    jlt_impl,
    jgt_impl};

void execute_comparison(instruction *instr);

typedef bool (*tobool_func_t)(avm_memcell *); // slide 28 dialexi 15

bool number_tobool(avm_memcell *m);

bool string_tobool(avm_memcell *m);

bool bool_tobool(avm_memcell *m);

bool table_tobool(avm_memcell *m);

bool userfunc_tobool(avm_memcell *m);

bool libfunc_tobool(avm_memcell *m);

bool nil_tobool(avm_memcell *m);

bool undef_tobool(avm_memcell *m);

tobool_func_t toboolFuncs[] = { // slide 28 dialexi 15
    number_tobool,
    string_tobool,
    bool_tobool,
    table_tobool,
    userfunc_tobool,
    libfunc_tobool,
    nil_tobool,
    undef_tobool};

bool avm_tobool(avm_memcell *m);

void read_binary_file();

void initialize();