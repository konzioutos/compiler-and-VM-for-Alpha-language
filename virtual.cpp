#include "virtual.h"

using namespace std;

// stack<SymbolTableEntry *> funcstack;

static void avm_initstack() // slide 17 dialexi 13s
{
    for (unsigned i = 0; i < AVM_STACKSIZE; i++)
    {
        AVM_WIPEOUT(vm_stack[i]);
        vm_stack[i].type = undef_m;
    }
    top = AVM_STACKSIZE - 1 - GlobalVars;
    topsp = top;
}

struct avm_table // slide 25 dialexi 13
{
    unsigned refCounter;
    unordered_multimap<avm_memcell *, avm_memcell *> strIndexed; // unorderded multimap pou einai h ylopoiisi hash table sth c++ anti gia c-style hash table
    unordered_multimap<avm_memcell *, avm_memcell *> numIndexed;
    unsigned total;
};

void avm_tableincrefcounter(avm_table *t) // slide 26 dialexi 13
{
    ++t->refCounter;
}

void avm_tabledecrefcounter(avm_table *t) // slide 26 dialexi 13
{
    assert(t->refCounter > 0);
    if (!--t->refCounter)
        avm_tabledestroy(t);
}

void avm_tablebucketsinit(unordered_multimap<avm_memcell *, avm_memcell *> hash_table) // slide 26 dialexi 13
{
    hash_table.clear();
}

avm_table *avm_tablenew() // slide 26 dialexi 13
{
    avm_table *t = new avm_table;
    t->refCounter = t->total = 0;
    t->strIndexed = {}; // arxikopoiisi twn hash
    t->numIndexed = {};

    AVM_WIPEOUT(*t);

    t->refCounter = t->total = 0;

    avm_tablebucketsinit(t->strIndexed);
    avm_tablebucketsinit(t->numIndexed);

    return t;
}

void memclear_string(avm_memcell *m)
{
    m->strVal.clear();
}

void memclear_table(avm_memcell *m)
{
    assert(m->tableVal);
    avm_tabledecrefcounter(m->tableVal);
}
typedef void (*memclear_func_t)(avm_memcell *);

memclear_func_t memclearFuncs[] = {
    0, /*number*/
    memclear_string,
    0, /*bool*/
    memclear_table,
    0, /*userfunc*/
    0, /*libfunc*/
    0, /*nil*/
    0, /*undef*/
};

void avm_memcellclear(avm_memcell *m) // slide 16 dialexi 15
{
    if (m->type != undef_m)
    {
        memclear_func_t f = memclearFuncs[m->type];
        if (f)
            (*f)(m);
        m->type = undef_m;
    }
}

void avm_tablebucketsdestroy(unordered_multimap<avm_memcell *, avm_memcell *> hash_table)
{
    auto lookupBind = hash_table.begin();
    for (lookupBind = hash_table.begin(); lookupBind != hash_table.end(); lookupBind++)
    {
        avm_memcellclear(lookupBind->first);
        avm_memcellclear(lookupBind->second);
    }
    hash_table.clear();
}

void avm_tabledestroy(avm_table *t)
{
    avm_tablebucketsdestroy(t->strIndexed);
    avm_tablebucketsdestroy(t->numIndexed);
    free(t); // delete t;
}

avm_memcell *hash_lookup(unordered_multimap<avm_memcell *, avm_memcell *> hash_table, avm_memcell *key, avm_memcell_t type)
{
    auto lookupBind = hash_table.begin();
    for (lookupBind = hash_table.begin(); lookupBind != hash_table.end(); lookupBind++)
    {
        if (key->type == number_m)
        {
            if (lookupBind->first->numVal == key->numVal)
            {
                return lookupBind->second;
            }
        }
        else if (key->type == string_m)
        {

            if (lookupBind->first->strVal == key->strVal)
            {
                return lookupBind->second;
            }
        }
    }
    if (lookupBind == hash_table.end())
    {
        return NULL;
    }
    return NULL;
}

int assign_counter = 0;

double consts_getnumber(unsigned index) // slide 8 dialexi 15
{
    return numConsts[index];
}
string consts_getstring(unsigned index) // slide 8 dialexi 15
{
    return stringConsts[index - 1];
}
string libfuncs_getused(unsigned index) // slide 8 dialexi 15
{

    return namedLibFuncs[index - 1];
}

avm_memcell *avm_translate_operand(vmarg *arg, avm_memcell *reg) // slide 8 dialexi 15
{
    avm_memcell *tmp = new avm_memcell;
    switch (arg->type)
    {

    case global_a:
        tmp = &vm_stack[AVM_STACKSIZE - arg->val - 1];
        return tmp;
    case local_a:
        return &vm_stack[topsp - arg->val];
    case formal_a:
        return &vm_stack[topsp + AVM_STACKENV_SIZE + 1 + arg->val];

    case retval_a:
        return &retval;

    case number_a:
    {

        reg->type = number_m;
        reg->numVal = consts_getnumber(arg->val);
        return reg;
    }
    case string_a:
    {

        reg->type = string_m;
        reg->strVal = consts_getstring(arg->val);
        return reg;
    }
    case bool_a:
    {
        reg->type = bool_m;
        reg->boolVal = arg->val;
        return reg;
    }
    case nil_a:
    {
        reg->type = nil_m;
        return reg;
    }

    case userfunc_a:
    {
        reg->type = userfunc_m;
        reg->funcVal = userFuncs[arg->val].address; // arg->val; den douleue me to index opote pairnw ti timi apo ton vector
        return reg;
    }
    case libfunc_a:
    {
        reg->type = libfunc_m;
        reg->libfuncVal = libfuncs_getused(arg->val);
        return reg;
    }

    default:
        assert(0);
    }
}

void execute_uminus(instruction *)
{
    ;
}

void execute_and(instruction *)
{
    ;
}
void execute_or(instruction *)
{
    ;
}

void execute_not(instruction *)
{
    ;
}

void execute_return(instruction *)
{
    ;
}

void execute_getretval(instruction *)
{
    ;
}

void execute_nop(instruction *)
{
    ;
}

void execute_jump(instruction *instr)
{
    if (!executionFinished && instr->result)
        pc = instr->result->val;
}

void execute_cycle() // slide 14 dialexi 15
{
    if (executionFinished)
    {
        return;
    }
    else if (pc == AVM_ENDING_PC)
    {
        executionFinished = 1;
        return;
    }
    else
    {

        assert(pc < AVM_ENDING_PC);

        instruction *instr = instructions[pc];

        if (instr->srcLine)
            currLine = instr->srcLine;
        unsigned oldPC = pc;

        (*executeFuncs[instr->opcode])(instr);

        if (pc == oldPC)
        {
            pc++;
        }
    }
}

void avm_warning(char *format, ...);

void avm_assign(avm_memcell *lv, avm_memcell *rv);

void execute_assign(instruction *instr) // slide 17 dialexi 15
{
    avm_memcell *lv = avm_translate_operand(instr->result, NULL);
    avm_memcell *rv = avm_translate_operand(instr->arg1, &ax);

    assert(rv);
    avm_assign(lv, rv);
    assign_counter++;
}

void avm_assign(avm_memcell *lv, avm_memcell *rv) // slide 18 dialexi 15
{

    if (lv == rv) // same cells? destructive to assign
        return;

    if (lv->type == table_m && // same tables -> no need to assign
        rv->type == table_m &&
        lv->tableVal == rv->tableVal)
        return;

    if (rv->type == undef_m) // from undefined r-values? warn
        cout << "Warning assigning from 'undef' content!" << endl;

    avm_memcellclear(lv); // clear old cell contents

    memcpy(lv, rv, sizeof(avm_memcell));

    if (lv->type == string_m)
    {
        lv->strVal = rv->strVal;
    }
    else if (lv->type == table_m)
    {
        lv->tableVal = rv->tableVal;
        avm_tableincrefcounter(lv->tableVal);
    }
}

void execute_call(instruction *instr) // slide 19 dialexi 15
{
    avm_memcell *func = avm_translate_operand(instr->arg1, &ax);
    assert(func);
    avm_callsaveenvironment();
    avm_memcell *cell = new avm_memcell;
    cell->type = string_m;
    cell->strVal = "\"()\"";

    switch (func->type)
    {

    case userfunc_m:
    {
        pc = userFuncs[func->funcVal].address;
        break;
    }
    case string_m:
        avm_calllibfunc(func->strVal);
        break;
    case libfunc_m:
        avm_calllibfunc(func->libfuncVal);
        break;
    default:
    {
        string s = avm_tostring(func);
        cout << "Error: call: cannot bind " << s << " to function! Line " << instr->srcLine << endl;
        executionFinished = 1;
        exit(1);
    }
    }
}

unsigned totalActuals = 0;

void avm_dec_top() // slide 20 dialexi 15
{
    if (!top)
    {
        cout << "Stack overflow." << endl;
        executionFinished = 1;
        exit(1);
    }
    else
        --top;
}

void avm_push_envvalue(unsigned val) // slide 20 dialexi 15
{
    vm_stack[top].type = number_m;
    vm_stack[top].numVal = val;
    avm_dec_top();
}

void avm_callsaveenvironment() // slide 20 dialexi 15
{
    avm_push_envvalue(totalActuals);
    avm_push_envvalue(pc + 1);
    avm_push_envvalue(top + totalActuals + 2);
    avm_push_envvalue(topsp);
}

void execute_funcenter(instruction *instr) // slide 21 dialexi 15
{
    avm_memcell *func = avm_translate_operand(instr->result, &ax);
    assert(func);
    assert(pc == func->funcVal);

    totalActuals = 0;
    // userfunc *funcInfo = avm_getfuncinfo(pc);
    topsp = top;
    top = top - userFuncs[func->funcVal].localSize - 1; // mporei na thelei kai -1 meta to localSize
}

unsigned avm_get_envvalue(unsigned i) // slide 21 dialexi 15
{
    assert(vm_stack[i].type == number_m);
    unsigned val = (unsigned)vm_stack[i].numVal;
    return val;
}

void execute_funcexit(instruction *instr) // slide 21 dialexi 15
{
    unsigned oldTop = top;
    top = avm_get_envvalue(topsp + AVM_SAVEDTOP_OFFSET);
    pc = avm_get_envvalue(topsp + AVM_SAVEDPC_OFFSET);
    topsp = avm_get_envvalue(topsp + AVM_SAVEDTOPSP_OFFSET);

    while (++oldTop <= top)
        avm_memcellclear(&vm_stack[oldTop]);
}

vector<library_func> libraries_vector;

unsigned avm_totalactuals() // slide 23 dialexi 15
{
    return avm_get_envvalue(topsp + AVM_NUMACTUALS_OFFSET);
}

avm_memcell *avm_getactual(unsigned i)
{
    assert(i < avm_totalactuals());
    // cout <<"actual: "<<  endl;
    return &vm_stack[topsp + AVM_STACKENV_SIZE + 1 + i];
}

void libfunc_print() // slide 35 front 5
{
    unsigned n = avm_totalactuals();
    for (int i = 0; i < n; i++)
    {
        string s = avm_tostring(avm_getactual(i));
        cout << s << endl;
    }
}

void libfunc_input()
{
    string input;
    cin >> input;
    bool isNumber = false;
    int dot_counters = 0;
    int l = 0;
    string s = input;
    string::iterator it;

    // Traverse the string
    for (it = input.begin(); it != input.end(); it++)
    {
        if (*it == '.')
        {
            isNumber = true;
            dot_counters++;
        }
        else if (!isdigit(*it))
        {
            isNumber = false;
            break;
        }

        if (dot_counters > 1)
        {
            isNumber = false;
            break;
        }
    }
    if (isNumber == true)
    {
        retval.numVal = stod(input);
        retval.type = number_m;
    }
    else
    {
        if (input == "true")
        {
            retval.boolVal = true;
            retval.type = bool_m;
        }
        else if (input == "false")
        {
            retval.boolVal = false;
            retval.type = bool_m;
        }
        else if (input == "nil")
        {
            retval.type = nil_m;
        }
        else
        {
            retval.type = string_m;
            retval.strVal = input;
        }
    }
    // cout << "INPUT----------->>>>>>>>>" << retval.strVal << endl;
}

void libfunc_objectmemberkeys()
{
    unsigned n = avm_totalactuals();
    if (n != 1)
    {
        cout << "Error: one argument(not " << n << " ) expected in 'objectmemberkeys'!" << endl;
        executionFinished = 1;
        exit(1);
    }
    avm_memcell *arg = avm_getactual(0);
    if (arg->type != table_m)
    {
        cout << "Error:Argument in objectmemberkeys is not table !" << endl;
        executionFinished = 1;
        exit(1);
    }
    avm_table *table = avm_tablenew();
    retval.tableVal = avm_tablenew();
    retval.type = table_m;
    int temp_key_val = 0;
    auto lookupBind = arg->tableVal->numIndexed.begin();
    for (lookupBind = arg->tableVal->numIndexed.begin(); lookupBind != arg->tableVal->numIndexed.end(); lookupBind++)
    {
        avm_memcell *new_key = new avm_memcell;
        avm_memcell *new_value = new avm_memcell;
        new_key->type = number_m;
        new_key->numVal = temp_key_val++;
        new_value->type = lookupBind->first->type;

        if (lookupBind->first->type == number_m)
            new_value->numVal = lookupBind->first->numVal;
        else if (lookupBind->first->type == string_m)
            new_value->strVal = lookupBind->first->strVal;
        else if (lookupBind->first->type == bool_m)
            new_value->boolVal = lookupBind->first->boolVal;
        else if (lookupBind->first->type == userfunc_m)
            new_value->funcVal = lookupBind->first->funcVal;
        else if (lookupBind->first->type == libfunc_m)
            new_value->libfuncVal = lookupBind->first->libfuncVal;
        else if (lookupBind->first->type == table_m)
        {
            avm_tableincrefcounter(lookupBind->first->tableVal);
            new_value->tableVal = lookupBind->first->tableVal;
        }
        // cout << "OBJECT NEW KEY---->>>" << new_key->numVal << endl;
        // cout << "OBJECT NEW VAL---->>>" << new_value->numVal << endl;
        retval.tableVal->total = table->total + 1;
        (retval.tableVal->numIndexed).insert({new_key, new_value});
    }
    auto lookupBind1 = arg->tableVal->strIndexed.begin();
    for (lookupBind1 = arg->tableVal->strIndexed.begin(); lookupBind1 != arg->tableVal->strIndexed.end(); lookupBind1++)
    {
        avm_memcell *new_key = new avm_memcell;
        avm_memcell *new_value = new avm_memcell;
        new_key->type = number_m;
        new_key->numVal = temp_key_val++;
        new_value->type = lookupBind1->first->type;
        if (lookupBind1->first->type == number_m)
            new_value->numVal = lookupBind1->first->numVal;
        else if (lookupBind1->first->type == string_m)
            new_value->strVal = lookupBind1->first->strVal;
        else if (lookupBind1->first->type == bool_m)
            new_value->boolVal = lookupBind1->first->boolVal;
        else if (lookupBind1->first->type == userfunc_m)
            new_value->funcVal = lookupBind1->first->funcVal;
        else if (lookupBind1->first->type == libfunc_m)
            new_value->libfuncVal = lookupBind1->first->libfuncVal;
        else if (lookupBind1->first->type == table_m)
        {
            avm_tableincrefcounter(lookupBind1->first->tableVal);
            new_value->tableVal = lookupBind1->first->tableVal;
        }
        retval.tableVal->total = table->total + 1;
        // cout << "OBJECT NEW KEY---->>>" << new_key->numVal << endl;
        //  cout << "OBJECT NEW VAL---->>>" << new_value->strVal << endl;
        (retval.tableVal->strIndexed).insert({new_key, new_value});
    }
}

void libfunc_objecttotalmembers()
{
    unsigned n = avm_totalactuals();
    if (n != 1)
    {
        cout << "Error: one argument(not " << n << " ) expected in 'objecttotalmembers'!" << endl;
        executionFinished = 1;
        exit(1);
    }
    avm_memcell *arg = avm_getactual(0);
    if (arg->type != table_m)
    {
        cout << "Error:Argument in objecttotalmembers is not table !" << endl;
        executionFinished = 1;
        exit(1);
    }
    retval.type = number_m;
    retval.numVal = arg->tableVal->total;
    cout << "objecttotalmembers----->>>>>" << retval.numVal << endl;
}

void libfunc_objectcopy()
{
    unsigned n = avm_totalactuals();
    if (n != 1)
    {
        cout << "Error: one argument(not " << n << " ) expected in 'objectcopy'!" << endl;
        executionFinished = 1;
        exit(1);
    }
    avm_memcell *arg = avm_getactual(0);
    if (arg->type != table_m)
    {
        cout << "Error:Argument in objectcopy is not table !" << endl;
        executionFinished = 1;
        exit(1);
    }
    retval.type = table_m;
    retval.tableVal = arg->tableVal;
    // cout << "OBJECT_COPY" << retval.tableVal->numIndexed;
    // cout << "OBJECT_COPY" << retval.tableVal->strIndexed;
}

void libfunc_argument()
{
    unsigned n = avm_totalactuals();
    avm_memcellclear(&retval);
    if (n != 1)
    {
        cout << "Error: one argument(not " << n << " ) expected in 'argument'!" << endl;
        executionFinished = 1;
        exit(1);
    }
    if (avm_getactual(0)->type != number_m)
    {
        cout << "Error:Argument in argument is not number !" << endl;
        executionFinished = 1;
        exit(1);
    }
    unsigned prev_topsp = avm_get_envvalue(topsp + AVM_SAVEDTOPSP_OFFSET);

    if (!prev_topsp)
    {
        cout << "'argument' called outside a function!" << endl;
        executionFinished = 1;
        retval.type = nil_m;
        exit(1);
    }
    else
    {
        avm_memcell *tmp = &vm_stack[prev_topsp + 1 + AVM_STACKENV_SIZE + avm_get_envvalue(topsp + AVM_STACKENV_SIZE + 1)];
        retval.type = tmp->type;
        if (tmp->type == number_m)
        {
            retval.numVal = tmp->numVal;
            // cout << "ARGUMENT----->>>>>>>>>" << retval.numVal << endl;
        }
        else if (tmp->type == string_m)
        {
            retval.strVal = tmp->strVal;
        }
        else if (tmp->type == bool_m)
        {
            retval.boolVal = tmp->boolVal;
        }
        else if (tmp->type == table_m)
        {
            retval.tableVal = tmp->tableVal;
        }
        else if (tmp->type == userfunc_m)
        {
            retval.funcVal = tmp->funcVal;
        }
        else if (tmp->type == libfunc_m)
        {
            retval.libfuncVal = tmp->libfuncVal;
        }
    }
}

void libfunc_strtonum()
{
    unsigned n = avm_totalactuals();
    avm_memcellclear(&retval);
    if (n != 1)
    {
        cout << "Error: one argument(not " << n << " ) expected in 'strtonum'!" << endl;
        executionFinished = 1;
        exit(1);
    }
    if (avm_getactual(0)->type != string_m)
    {
        cout << "Error:Argument in strtonum is not string !" << endl;
        executionFinished = 1;
        exit(1);
    }
    string arg = avm_tostring(avm_getactual(0));
    arg = string(++arg.begin(), --arg.end());
    bool isNumber = false;
    int dot_counters = 0;
    int l = 0;
    while (l < arg.length())
    {
        if (arg[l] == '.')
        {
            isNumber = true;
            dot_counters++;
        }
        else if (!isdigit(arg[l]))
        {
            isNumber = false;
            break;
        }

        if (dot_counters > 1)
        {
            isNumber = false;
            break;
        }
        l++;
    }

    if (isNumber == false)
    {
        retval.type = nil_m;
    }
    else
    {
        retval.numVal = stod(arg);
        retval.type = number_m;
    }
    // cout << "strtonum->" << retval.numVal << endl;
}

void libfunc_sqrt()
{
    unsigned n = avm_totalactuals();
    if (n != 1)
    {
        cout << "Error: one argument(not " << n << " ) expected in 'sqrt'!" << endl;
        executionFinished = 1;
        exit(1);
    }
    avm_memcell *arg = avm_getactual(0);
    if (avm_getactual(0)->type != number_m)
    {
        cout << "Error:Argument in sqrt is not numer !" << endl;
        executionFinished = 1;
        exit(1);
    }
    avm_memcellclear(&retval);
    retval.type = nil_m;
    bool isNumber = false;
    int dot_counters = 0;
    if (arg->numVal >= 0)
    {
        retval.numVal = sqrt(arg->numVal);
        retval.type = number_m;
    }
    // cout << "sqrt->" << retval.numVal << endl;
}

void libfunc_cos()
{
    unsigned n = avm_totalactuals();
    if (n != 1)
    {
        cout << "Error: one argument(not " << n << " ) expected in 'cos'!" << endl;
        executionFinished = 1;
        exit(1);
    }
    avm_memcell *arg = avm_getactual(0);
    if (arg->type != number_m)
    {
        cout << "Error:Argument in cos is not numer !" << endl;
        executionFinished = 1;
        exit(1);
    }
    avm_memcellclear(&retval);
    retval.numVal = cos(arg->numVal * 3.14159265 / 180.0);
    retval.type = number_m;
    // cout << "cos->" << retval.numVal << endl;
}

void libfunc_sin()
{
    unsigned n = avm_totalactuals();
    if (n != 1)
    {
        cout << "Error: one argument(not " << n << " ) expected in 'sin'!" << endl;
        executionFinished = 1;
        exit(1);
    }
    avm_memcell *arg = avm_getactual(0);
    if (arg->type != number_m)
    {
        cout << "Error:Argument in sin is not numer !" << endl;
        executionFinished = 1;
        exit(1);
    }
    avm_memcellclear(&retval);
    retval.numVal = sin(arg->numVal * 3.14159265 / 180.0);
    retval.type = number_m;
    // cout << "sin->" << retval.numVal << endl;
}

void libfunc_totalarguments() // slide 36 dialexi 15
{

    unsigned prev_topsp = avm_get_envvalue(topsp + AVM_SAVEDTOP_OFFSET);
    avm_memcellclear(&retval);

    if (!prev_topsp)
    {
        cout << "'totalarguments' called outside a function!" << endl;
        executionFinished = 1;
        retval.type = nil_m;
        exit(1);
    }
    else
    {
        retval.type = number_m;
        retval.numVal = avm_get_envvalue(prev_topsp + 8); // 2 * AVM_NUMACTUALS_OFFSET
    }
    // cout << "Total Arguments of function are:" << retval.numVal << endl;
}

void libfunc_typeof() // slide 36 front 5
{
    unsigned n = avm_totalactuals();
    if (n != 1)
    {
        cout << "Error: one argument(not " << n << " ) expected in 'typeof'!" << endl;
        executionFinished = 1;
        exit(1);
    }
    else
    {
        avm_memcellclear(&retval);
        retval.type = string_m;
        retval.strVal = typeStrings[avm_getactual(0)->type];
    }
    // cout << "typeof->>>" << retval.strVal << endl;
}

library_func_t avm_getlibraryfunc(string id)
{
    library_func_t tmp;
    if (id == "print")
    {
        tmp = libfunc_print;
    }
    else if (id == "input")
    {
        tmp = libfunc_input;
    }
    else if (id == "objectmemberkeys")
    {
        tmp = libfunc_objectmemberkeys;
    }
    else if (id == "objecttotalmembers")
    {
        tmp = libfunc_objecttotalmembers;
    }
    else if (id == "objectcopy")
    {
        tmp = libfunc_objectcopy;
    }
    else if (id == "totalarguments")
    {
        tmp = libfunc_totalarguments;
    }
    else if (id == "argument")
    {
        tmp = libfunc_argument;
    }
    else if (id == "typeof")
    {
        tmp = libfunc_typeof;
    }
    else if (id == "strtonum")
    {
        tmp = libfunc_strtonum;
    }
    else if (id == "sqrt")
    {
        tmp = libfunc_sqrt;
    }
    else if (id == "cos")
    {
        tmp = libfunc_cos;
    }
    else if (id == "sin")
    {
        tmp = libfunc_sin;
    }
    return tmp;
}

void avm_calllibfunc(string id) // slide 22 dialexi 15
{
    library_func_t f = avm_getlibraryfunc(id);

    if (!f)
    {
        cout << "Error:Unsupported lib func " << id << " called!" << endl;
        executionFinished = 1;
        exit(1);
    }
    else
    {
        topsp = top;
        totalActuals = 0;
        (*f)();
        if (!executionFinished)
            execute_funcexit((instruction *)0);
    }
}

void avm_registerlibfunc(string id, library_func_t addr)
{
    library_func f;
    f.addr = avm_getlibraryfunc(id);
    f.id = id;
    libraries_vector.push_back(f);
}

void execute_pusharg(instruction *instr) // slide 24 dialexi 15
{

    // cout << "instr: "<<instr->srcLine<<endl;
    // cout << "ax: "<<ax.type<<endl;
    // cout << "arg1Type: " <<instr->arg1->type<<endl;
    avm_memcell *arg = avm_translate_operand(instr->arg1, &ax);
    // cout << "arg: " << arg->type<<endl<<endl;
    assert(arg);
    avm_assign(&vm_stack[top], arg);
    ++totalActuals;
    avm_dec_top();
}

string number_tostring(avm_memcell *m) // slide 23 dialexi 15
{
    return to_string(m->numVal);
}
string string_tostring(avm_memcell *m) // slide 23 dialexi 15
{
    return m->strVal;
}
string bool_tostring(avm_memcell *m) // slide 23 dialexi 15
{
    if (m->boolVal == true)
    {
        return "true";
    }
    else
    {
        return "false";
    }
}
string table_tostring(avm_memcell *m) // slide 23 dialexi 15
{
    string table = "[ ";
    auto lookupBind = m->tableVal->numIndexed.begin();
    for (lookupBind = m->tableVal->numIndexed.begin(); lookupBind != m->tableVal->numIndexed.end(); lookupBind++)
    {
        table += "{";
        table += to_string(lookupBind->first->numVal);
        table += " : ";
        table += avm_tostring(lookupBind->second);
        table += "} ";
    }
    auto lookupBind1 = m->tableVal->strIndexed.begin();
    for (lookupBind1 = m->tableVal->strIndexed.begin(); lookupBind1 != m->tableVal->strIndexed.end(); lookupBind1++)
    {
        table += ", {";
        table += lookupBind->first->strVal;
        table += " : ";
        table += avm_tostring(lookupBind->second);
        table += "} ";
    }
    table += "]";
    return table;
}
string userfunc_tostring(avm_memcell *m) // slide 23 dialexi 15
{
    assert(m);
    assert(m->type == userfunc_m);
    string tmp = to_string(m->funcVal);
    return tmp;
}
string libfunc_tostring(avm_memcell *m) // slide 23 dialexi 15
{
    assert(m);
    assert(m->type == libfunc_m);
    string tmp = m->libfuncVal;
    return tmp;
}
string nil_tostring(avm_memcell *m) // slide 23 dialexi 15
{
    assert(m);
    assert(m->type == nil_m);
    string tmp = "Nil";
    return tmp;
}
string undef_tostring(avm_memcell *m) // slide 23 dialexi 15
{
    assert(m);
    assert(m->type == undef_m);
    string tmp = "Undef";
    return tmp;
}

string avm_tostring(avm_memcell *m) // slide 24 dialexi 15
{
    assert(m->type >= 0 & m->type <= undef_m);
    return (*tostringFuncs[m->type])(m);
}

double add_impl(double x, double y) // slide 25 dialexi 15
{
    return x + y;
}
double sub_impl(double x, double y) { return x - y; } // slide 25 dialexi 15
double mul_impl(double x, double y) { return x * y; } // slide 25 dialexi 15
double div_impl(double x, double y)                   // slide 25 dialexi 15
{
    if (y == 0)
    {
        cout << "Runtime_error:Math error: Attempted to divide by Zero" << endl;
        exit(1);
    }
    else
    {
        return x / y;
    }
}
double mod_impl(double x, double y) // slide 25 dialexi 15
{
    if (y == 0)
    {
        cout << "Runtime_error:Math error: Attempted to divide by Zero" << endl;
        exit(1);
    }
    else
    {
        // cout << "MOD:" << fmod(x, y) << endl;
        return fmod(x, y);
    }
}

void execute_arithmetic(instruction *instr) // slide 25 dialexi 15
{
    avm_memcell *lv = avm_translate_operand(instr->result, (avm_memcell *)0);
    avm_memcell *rv1 = avm_translate_operand(instr->arg1, &ax);
    avm_memcell *rv2 = avm_translate_operand(instr->arg2, &bx);

    assert(lv && (&vm_stack[AVM_STACKSIZE - 1] >= lv && lv > &vm_stack[top] || lv == &retval));
    assert(rv1 && rv2);
    if (rv1->type != number_m || rv2->type != number_m)
    {
        cout << "Error:Not a number in arithmetic" << endl;
        ;
        executionFinished = 1;
        exit(1);
    }
    else
    {
        arithmetic_func_t op = arithmeticFuncs[instr->opcode - add_v];
        avm_memcellclear(lv);
        lv->type = number_m;
        lv->numVal = (*op)(rv1->numVal, rv2->numVal);
    }
}

bool jge_impl(double x, double y)
{
    if (x >= y)
        return true;
    else
        return false;
}
bool jgt_impl(double x, double y)
{
    if (x > y)
        return true;
    else
        return false;
}
bool jle_impl(double x, double y)
{
    if (x <= y)
        return true;
    else
        return false;
}
bool jlt_impl(double x, double y)
{
    if (x < y)
        return true;
    else
        return false;
}

void execute_comparison(instruction *instr)
{
    //  avm_memcell *lv = avm_translate_operand(instr->result, (avm_memcell *)0);
    avm_memcell *rv1 = avm_translate_operand(instr->arg1, &ax); // antistoixa me to arithmetic omws twra xreiazomai ta duo arguments mono kai oxi to result
    avm_memcell *rv2 = avm_translate_operand(instr->arg2, &bx);

    assert(rv1 && rv2);
    if (rv1->type == undef_m || rv2->type == undef_m)
    {
        cout << "Runtime Error:undef involded in comparison";
        executionFinished = 1;
        exit(1);
    }
    else if (rv1->type != number_m || rv2->type != number_m)
    {
        cout << "Error:Not a number in comparison operation";
        executionFinished = 1;
        exit(1);
    }
    else
    {
        cmp_func op = comparisonFuncs[instr->opcode - jle_v];
        // cout << op << endl;

        bool res = (*op)(rv1->numVal, rv2->numVal);
        // cout << "COMPARISON RESULT---->>>" << res << endl;
        if (!executionFinished && res)
        {
            pc = instr->result->val;
        }
    }
}

typedef bool (*tobool_func_t)(avm_memcell *); // slide 28 dialexi 15

bool number_tobool(avm_memcell *m) { return m->numVal != 0; }  // slide 28 dialexi 15
bool string_tobool(avm_memcell *m) { return m->strVal != ""; } // slide 28 dialexi 15
bool bool_tobool(avm_memcell *m) { return m->boolVal; }        // slide 28 dialexi 15
bool table_tobool(avm_memcell *m) { return 1; }                // slide 28 dialexi 15
bool userfunc_tobool(avm_memcell *m) { return 1; }             // slide 28 dialexi 15
bool libfunc_tobool(avm_memcell *m) { return 1; }              // slide 28 dialexi 15
bool nil_tobool(avm_memcell *m) { return 0; }                  // slide 28 dialexi 15
bool undef_tobool(avm_memcell *m)                              // slide 28 dialexi 15
{
    assert(0);
    return 0;
}

bool avm_tobool(avm_memcell *m) // slide 28 dialexi 15
{
    assert(m->type >= 0 && m->type < undef_m);
    return (*toboolFuncs[m->type])(m);
}

void execute_jeq(instruction *instr) // slide 29 dialexi 15
{
    assert(instr->result->type == label_a);
    avm_memcell *rv1 = avm_translate_operand(instr->arg1, &ax);
    avm_memcell *rv2 = avm_translate_operand(instr->arg2, &bx);
    bool result = 0;
    if (rv1->type == undef_m || rv2->type == undef_m)
    {
        cout << "Error: 'undef' ivolved in equality!";
        executionFinished = 1;
        exit(1);
    }
    else if (rv1->type == nil_m || rv2->type == nil_m)
        result = rv1->type == nil_m && rv2->type == nil_m;
    else if (rv1->type == bool_m || rv2->type == bool_m)
        result = (avm_tobool(rv1) == avm_tobool(rv2));
    else if (rv1->type != rv2->type)
    {
        cout << "Error: \" " << typeStrings[rv1->type] << " == " << typeStrings[rv2->type] << "is illegal! \" " << endl;
        executionFinished = 1;
        exit(1);
    }
    else
    {
        switch (rv1->type)
        {
        case number_m:
            if (rv1->numVal == rv2->numVal)
                result = true;
            else
                result = false;
            break;
        case string_m:
            if (rv1->strVal == rv2->strVal)
                result = true;
            else
                result = false;
            break;
        case table_m:
            if (rv1->tableVal == rv2->tableVal)
                result = true;
            else
                result = false;
            break;
        case userfunc_m:
            if (rv1->funcVal == rv2->funcVal)
                result = true;
            else
                result = false;
            break;
        case libfunc_m:
            if (rv1->libfuncVal == rv2->libfuncVal)
                result = true;
            else
                result = false;
            break;
        default:
            assert(0);
        }
    }

    if (!executionFinished && result)
        pc = instr->result->val;
}

void execute_jne(instruction *instr) // na to tsekarw, exw amfivolia an douleuoun swsta ta result
{
    assert(instr->result->type == label_a);

    avm_memcell *rv1 = avm_translate_operand(instr->arg1, &ax);
    avm_memcell *rv2 = avm_translate_operand(instr->arg2, &bx);

    bool result = 0;

    if (rv1->type == undef_m || rv2->type == undef_m)
    {
        cout << "Error: 'undef' ivolved in inequality!";
        executionFinished = 1;
        exit(1);
    }
    else if (rv1->type == nil_m || rv2->type == nil_m)
        result = rv1->type != nil_m && rv2->type != nil_m;
    else if (rv1->type == bool_m || rv2->type == bool_m)
        result = (avm_tobool(rv1) != avm_tobool(rv2));
    else if (rv1->type != rv2->type)
    {
        cout << "Error: \" " << typeStrings[rv1->type] << " == " << typeStrings[rv2->type] << "is illegal! \" " << endl;
        executionFinished = 1;
        exit(1);
    }
    else
    {
        switch (rv1->type)
        {
        case number_m:
            if (rv1->numVal != rv2->numVal)
                result = true;
            else
                result = false;
            break;
        case string_m:
            if (rv1->strVal != rv2->strVal)
                result = true;
            else
                result = false;
            break;
        case table_m:
            if (rv1->tableVal != rv2->tableVal)
                result = true;
            else
                result = false;
            break;
        case userfunc_m:
            if (rv1->funcVal != rv2->funcVal)
                result = true;
            else
                result = false;
            break;
        case libfunc_m:
            if (rv1->libfuncVal != rv2->libfuncVal)
                result = true;
            else
                result = false;
            break;
        default:
            assert(0);
        }
    }

    if (!executionFinished && result)
        pc = instr->result->val;
}

void execute_newtable(instruction *instr) // slide 31 dialexi 15
{
    avm_memcell *lv = avm_translate_operand(instr->arg1, (avm_memcell *)0);
    assert(lv && (&vm_stack[AVM_STACKSIZE - 1] >= lv && lv > &vm_stack[top] || lv == &retval));
    avm_memcellclear(lv);
    lv->type = table_m;
    lv->tableVal = avm_tablenew();
    avm_tableincrefcounter(lv->tableVal);
}

avm_memcell *avm_tablegetelem(avm_table *table, avm_memcell *key) // slide 32 dialexi 15
{
    avm_memcell *elem;
    if (key->type == number_m)
    {
        elem = hash_lookup(table->numIndexed, key, number_m);
        if (elem == NULL)
        {
            return NULL;
        }
        else
        {
            return elem; // mporei na thelei &
        }
    }
    else if (key->type == string_m)
    {
        elem = hash_lookup(table->strIndexed, key, string_m);
        if (elem == NULL)
        {
            return NULL;
        }
        else
        {
            return elem; // mporei na thelei &
        }
    }
    return NULL;
}

void avm_tablesetelem(avm_table *table, avm_memcell *index, avm_memcell *content)
{
    if (index->type == number_m && content->type != nil_m)
    {
        avm_memcell *new_key = new avm_memcell;
        avm_memcell *new_value = new avm_memcell;
        new_key->type = number_m;
        new_key->numVal = index->numVal;
        new_value->type = content->type;
        if (content->type == number_m)
            new_value->numVal = content->numVal;
        else if (content->type == string_m)
            new_value->strVal = content->strVal;
        else if (content->type == bool_m)
            new_value->boolVal = content->boolVal;
        else if (content->type == userfunc_m)
            new_value->funcVal = content->funcVal;
        else if (content->type == libfunc_m)
            new_value->libfuncVal = content->libfuncVal;
        else if (content->type == table_m)
        {
            avm_tableincrefcounter(content->tableVal);
            new_value->tableVal = content->tableVal;
        }
        table->total = table->total + 1;
        (table->numIndexed).insert({new_key, new_value});
    }
    else if (index->type == number_m && content->type == nil_m)
    {
        table->numIndexed.erase(index);
        table->total = table->total - 1;
    }
    else if (index->type == string_m && content->type != nil_m)
    {
        avm_memcell *new_key = new avm_memcell;
        avm_memcell *new_value = new avm_memcell;
        new_key->type = string_m;
        new_key->strVal = index->strVal;
        new_value->type = content->type;

        if (content->type == number_m)
            new_value->numVal = content->numVal;
        else if (content->type == string_m)
            new_value->strVal = content->strVal;
        else if (content->type == bool_m)
            new_value->boolVal = content->boolVal;
        else if (content->type == userfunc_m)
            new_value->funcVal = content->funcVal;
        else if (content->type == libfunc_m)
            new_value->libfuncVal = content->libfuncVal;
        else if (content->type == table_m)
        {
            avm_tableincrefcounter(content->tableVal);
            new_value->tableVal = content->tableVal;
        }
        // avm_assign(index, content);
        table->total = table->total + 1;
        (table->strIndexed).insert({new_key, new_value});
    }
    else if (index->type == string_m && content->type == nil_m)
    {
        table->strIndexed.erase(index);
        table->total = table->total - 1;
    }
}

void execute_tablegetelem(instruction *instr) // slide 32 dialexi 15
{
    avm_memcell *lv = avm_translate_operand(instr->result, (avm_memcell *)0);
    avm_memcell *t = avm_translate_operand(instr->arg1, (avm_memcell *)0);
    avm_memcell *i = avm_translate_operand(instr->arg2, &ax);

    assert(lv && (&vm_stack[AVM_STACKSIZE - 1] >= lv && lv > &vm_stack[top] || lv == &retval));
    assert(t && &vm_stack[AVM_STACKSIZE - 1] >= t && t > &vm_stack[top]);
    assert(i);

    avm_memcellclear(lv);
    lv->type = nil_m;

    if (t->type != table_m)
    {
        cout << "Error: Illegal use of type " << typeStrings[t->type] << " as a table!" << endl;
        executionFinished = 1;
        exit(1);
    }
    else
    {
        avm_memcell *content = avm_tablegetelem(t->tableVal, i);
        if (content)
        {
            avm_assign(lv, content);
        }
        else
        {
            string ts = avm_tostring(t);
            string is = avm_tostring(i);
            cout << "Warning " << ts << " [ " << is << " ] "
                 << "not found!" << endl;
        }
    }
}

void execute_tablesetelem(instruction *instr) // slide 33 dialexi 15
{
    avm_memcell *t = avm_translate_operand(instr->result, (avm_memcell *)0);
    avm_memcell *i = avm_translate_operand(instr->arg1, &ax);

    avm_memcell *c = avm_translate_operand(instr->arg2, &bx);

    assert(t && &vm_stack[AVM_STACKSIZE - 1] >= t && t > &vm_stack[top]);
    assert(i && c);

    if (t->type != table_m)
    {

        cout << "Error: Illegal use of type " << typeStrings[t->type] << " as a table" << endl;
        executionFinished = 1;
        exit(1);
    }
    else
    {
        avm_tablesetelem(t->tableVal, i, c);
    }
}

instruction *add_result(instruction *instr, vmarg_t type, unsigned val)
{
    instr->result = new vmarg;
    instr->result->val = val;
    instr->result->type = type;
    return instr;
}

instruction *add_arg1(instruction *instr, vmarg_t type, unsigned val)
{
    instr->arg1 = new vmarg;
    instr->arg1->val = val;
    instr->arg1->type = type;
    return instr;
}

instruction *add_arg2(instruction *instr, vmarg_t type, unsigned val)
{
    instr->arg2 = new vmarg;
    instr->arg2->val = val;
    instr->arg2->type = type;
    return instr;
}

instruction *initialize_instr(instruction *instr, int opcode, unsigned size)
{
    instr->opcode = static_cast<vmopcode>(opcode);
    instr->srcLine = size;
    return instr;
}

userfunc add_function(userfunc function, int address, int localSize, string id)
{
    function.address = address;
    function.localSize = localSize;
    function.id = id;
    return function;
}

void read_binary_file()
{
    ifstream binary_input("binary.abc", ios::in | ios::binary);
    unsigned address, localSize, val;
    double numConst;
    char inputChar, space;
    int MagicNumber, i, j, index, strLength, totalInstructions, opcode, type;
    string stringConst = "", libName, id, str;
    if (!binary_input.is_open())
    {
        cout << "Failed to open file!" << endl;
        return;
    }
    binary_input >> skipws >> str; // MagicNumber:
    binary_input >> skipws >> MagicNumber;
    if (MagicNumber != 340200501)
    {
        cout << "Error: This is not a .abc file!" << endl;
        exit(1);
    }
    binary_input >> skipws >> str; // MagicNumber:
    binary_input >> skipws >> GlobalVars;
    binary_input >> skipws >> str >> skipws >> str >> skipws >> totalNumConsts >> skipws >> str;
    for (i = 0; i < totalNumConsts; i++)
    {
        binary_input >> skipws >> index >> skipws >> str >> skipws >> numConst;
        numConsts.push_back(numConst);
    }
    for (i = 0; i < totalNumConsts; i++)
    {
        // cout << "NumConst" << i << ": " << numConsts.at(i) << endl;
    }
    binary_input >> skipws >> str >> skipws >> str >> skipws >> totalStringConsts >> skipws >> str;
    for (i = 0; i < totalStringConsts; i++)
    {
        binary_input >> skipws >> index >> skipws >> str >> skipws >> strLength >> skipws >> str >> noskipws >> space;

        stringConst = "";
        for (j = 0; j < strLength + 2; j++)
        {
            binary_input >> noskipws >> inputChar;
            // cout << inputChar <<endl;
            stringConst += inputChar;
            // cout << "strConst: " << stringConst <<endl;
        }
        // cout << "strConst: " <<stringConst <<endl;
        stringConsts.push_back(stringConst);
    }
    for (i = 0; i < totalStringConsts; i++)
    {
        // cout << "stringConst" << i << ": " << stringConsts.at(i) << endl;
    }
    binary_input >> skipws >> str >> skipws >> str >> skipws >> totalNamedLibfuncs >> skipws >> str;
    for (i = 0; i < totalNamedLibfuncs; i++)
    {
        binary_input >> skipws >> index >> skipws >> str >> skipws >> libName;
        namedLibFuncs.push_back(libName);
    }
    for (i = 0; i < totalNamedLibfuncs; i++)
    {
        // cout << "libName" << i << ": " << namedLibFuncs.at(i) << endl;
    }
    binary_input >> skipws >> str >> skipws >> str >> skipws >> totalUserFuncs >> skipws >> str;
    for (i = 0; i < totalUserFuncs; i++)
    {
        binary_input >> skipws >> index >> skipws >> str >> skipws >> str >> skipws >> address >> skipws >> str >> skipws >> localSize >> skipws >> str >> skipws >> id >> skipws >> str;
        userfunc function;

        userFuncs.push_back(add_function(function, address, localSize, id));
    }
    for (i = 0; i < totalUserFuncs; i++)
    {
        // cout << "userFunc" << i << "(address: " << userFuncs.at(i).address << ", localSize: " << userFuncs.at(i).localSize << ", id: " << userFuncs.at(i).id << ")" << endl;
    }

    binary_input >> skipws >> str >> skipws >> str >> skipws >> totalInstructions >> skipws >> str >> skipws >> str;

    instruction *instr;
    for (i = 0; i < totalInstructions; i++)
    {
        binary_input >> skipws >> opcode;
        instr = new instruction;
        instr = initialize_instr(instr, opcode, instructions.size());

        binary_input >> skipws >> str; // opcode:, result:, arg1:, arg2:
        if (str == "opcode:")
        {
            instructions.push_back(instr);
            continue;
        }
        if (str == "result:")
        {
            binary_input >> skipws >> str >> skipws >> type >> skipws >> str >> skipws >> val;
            instr = add_result(instr, static_cast<vmarg_t>(type), val);
            binary_input >> skipws >> str; // opcode:, arg1:, arg2:
            if (str == "opcode:")
            {
                instructions.push_back(instr);
                continue;
            }
        }
        if (str == "arg1:")
        {
            binary_input >> skipws >> str >> skipws >> type >> skipws >> str >> skipws >> val;
            instr = add_arg1(instr, static_cast<vmarg_t>(type), val);
            binary_input >> skipws >> str; // opcode:, arg2:
            if (str == "opcode:")
            {
                instructions.push_back(instr);
                continue;
            }
        }
        if (str == "arg2:")
        {
            binary_input >> skipws >> str >> skipws >> type >> skipws >> str >> skipws >> val;
            instr = add_arg2(instr, static_cast<vmarg_t>(type), val);
            binary_input >> skipws >> str; // opcode:,eof:
            if (str == "opcode:")
            {
                instructions.push_back(instr);
                continue;
            }
        }
        instructions.push_back(instr);
    }
    // cout << "Instructions: " << instructions.size() << endl;

    for (i = 0; i < totalInstructions; i++)
    {
        // cout << "Instruction " << i << ": " << endl;
        // cout << "   opcode:" << instructions.at(i)->opcode << endl;
        // if (instructions.at(i)->result != 0)
        //     cout << "        result: " << instructions.at(i)->result->type << ", " << instructions.at(i)->result->val << endl;
        //  if (instructions.at(i)->arg1 != 0)
        //     cout << "        arg1: " << instructions.at(i)->arg1->type << ", " << instructions.at(i)->arg1->val << endl;
        //  if (instructions.at(i)->arg2 != 0)
        //    cout << "        arg2: " << instructions.at(i)->arg2->type << ", " << instructions.at(i)->arg2->val << endl;
    }

    binary_input.close();
}

void initialize() // slide 35 dialexi 15
{
    avm_initstack();

    avm_registerlibfunc("print", libfunc_print);
    avm_registerlibfunc("input", libfunc_input);
    avm_registerlibfunc("objectmemberkeys", libfunc_objectmemberkeys);
    avm_registerlibfunc("objecttotalmembers", libfunc_objecttotalmembers);
    avm_registerlibfunc("objectcopy", libfunc_objectcopy);
    avm_registerlibfunc("totalarguments", libfunc_totalarguments);
    avm_registerlibfunc("argument", libfunc_argument);
    avm_registerlibfunc("typeof", libfunc_typeof);
    avm_registerlibfunc("strtonum", libfunc_strtonum);
    avm_registerlibfunc("sqrt", libfunc_sqrt);
    avm_registerlibfunc("cos", libfunc_cos);
    avm_registerlibfunc("sin", libfunc_sin);
}

int main()
{
    read_binary_file();
    initialize();
    codeSize = instructions.size();
    for (unsigned i = 0; i < AVM_STACKSIZE; i++)
    {
        // cout << "Stack:" << vm_stack[i].type << endl;
    }
    for (int i = 0; i < libraries_vector.size(); i++)
    {
        // cout << "libName: " << libraries_vector.at(i).id << endl;
    }
    while (executionFinished == 0)
    {
        execute_cycle();
    }
    cout << "Execution completed!!!" << endl;
    return 0;
}