/*

OUTLINE and PREMISE

Z.BASIC - An interpreter that runs inside a quest that
facilitates a shell window that allows the player to
modify or write ad-hoc scripts while the game is running.

v.0.4.5

If function pointers were working, that'd be far simpler, 
as I could enqueue instructions into main() in a quest script
In theory though, this would be a useful learning tool, as 
the user could encode very small scripts live, and have the 
quest execute them.

The syntax might be simplified, though.

It's the same premise as my TBA parser/interpreter, but with a 
different scope.

It'd be a for loop.

When the user adds instructions, and closes the interpreter, 
the instruction loop would be counted that'd be the loop operator.

Then the parser string matches the instruction and puts a value 
onto a stack. Once done, a switch block would call instructions 
based on the case values read from the stack
 
The switch block for those instructions would be huge:
One case per instruction in the engine, hence why *f() would be better.

It'd end up as some form of BASIC or Pascal, but the interface 
wouldn't allow declaring vars, only using extant, predefined 
vars.

Probably G0 through G1023, plus a set f 32 for each other 
datatype. We'd probably need to count how many values are
set in the script, when the interpreter scans it, then store
each value into an array index. 

The tricky part, is storing the 'current' vars passed to 
instructions

Probably would just be the array index of each, plus a set of 
temp vars in the parser to use for literals

It would be fun to construct it, but it would run at a fraction of the speed of ZScript

The parser would need to be able to store the values of 
literals to an array, and track when they are used.

We'd need to keep a count of the last var used in the switch
block when processing instructions, and for each param,
we increment the count after passing the value:

e.g.

*/


const int TOP = 1024;

int STACK[TOP];
int popmem; //colds the value popped from any stack.

const int MAX_STACK_REG = TOP - 1;
//The array pointer to the stack in use.
int curstack;
void CurStack(int a) { curstack = a; }
int CurStack() { return curstack; }

int SP; //0 is NULL
int RIP; //0 is NULL, register pointer
int CV; //current global var
int CSR; //current script ram index
int CPV; //current param value
int CVT; //cur vaqr type
int CVV; //current var value
int CVL; //current vartype length

int EXP1; //Expr Accumulator 1
int EXP2; //Expr Accumulator 1
int INDX1; //misc 1

int ZBASIc[256]; //used for returning arrays.

ffc script stack
{
	void run() {}
	int top() { return TOP; }
	int top(int a) { return SizeOfArray(a);; }
	void change(int b) { curstack = b; SP = b[TOP]; }
	void setCurStack(int b) { curstack = b; SP = b[TOP]; }
	int maxSize()
	{
		c = curstack;
		return ( SizeOfArray(c) - 1 );
	}
	void pop()
	{
		int c = curstack;
		if ( c < 1 ) 
		{
			TraceNL(); TraceS"Invalid stack called by stack.pop: "; Trace(c);
			return;
		}
		if ( isempty(c) ) 
		{
			TraceNL(); TraceS"Cannot pop from an empty stack. The empty stack was: "; Trace(c);
			return;
		}
		popmem = c[TOP];
		SP = --c[TOP];
		//--c[TOP];
		//SP = c[TOP];
	}
	void pop(int indx)
	{
		//RP = indx;
		int c = curstack;
		if ( c < 1 ) 
		{
			TraceNL(); TraceS"Invalid stack called by stack.pop: "; Trace(c);
			return;
		}
		if ( isempty(c) ) 
		{
			TraceNL(); TraceS"Cannot pop from an empty stack. The empty stack was: "; Trace(c);
			return;
		}
		indx = c[TOP];
		SP = --c[TOP];
		RIP = indx; //so, getSArg(RIP);
		//--c[TOP];
		//SP = c[TOP];
	}
	void push(int val)
	{
		int c = curstack;
		if ( c < 1 ) 
		{
			TraceNL(); TraceS"Invalid stack called by stack.push: "; Trace(c);
			return;
		}
		if ( isfull(c) )
		{
			TraceNL(); TraceS"Cannot push to a full stack. The full stack was: "; Trace(c);
			return;
		}
		c[TOP] = val;
		SP = ++c[TOP];
		//++c[TOP];
		//SP = c[TOP];
		//DO WE HAVE = -- IN zsCRIPT YET (ASSIGN (DECREMENT FIRST ))??
	}
	bool isempty(int a) { return (!a[TOP]); }
	bool isfull(int a) { return ( a[TOP] >= MAX_STACK_REG ); }
	
	void init(int a) { for ( int q = 0; q < TOP; ++q ) { a[q] = 0; }
	
		
}

int VARTYPES[TOP]; //0 is null. First valid memory index == 1

int count = 0; //the current index for storing or reading back variables when executing stack calls
int G[256];
int I[256];
ffc F[256];
npc N[256];
eweapon E[256];
lweapon L[256];
item IT[256];
itemdata ID[256];
npcdata ND[256];
spritedata WD[256];
combodata CD[256];
shopdata SD[256];
mapdata MD[256];

int WORD[64]; //HOLDS THHE CURRENT COMMAND
int PARAM[13]; //11 + sign + dot
int VARIABLE[7]; //type_id + 4 digits

int PARAMS[256];

int STACK[256]; //instruction IDs

int OPERAND[1024];
int OPERATOR[1024];

//maths
int operator_type; //current operator


const int TYPE_NULL = 0;
const int TYPE_GLOBAL = 1;
const int TYPE_INT = 2;
const int TYPE_NPC = 3;
const int TYPE_LWEAPON = 4;
const int TYPE_EWEAPON = 5;
const int TYPE_FFC = 6;
const int TYPE_ITEM = 7;
const int TYPE_ITEMDATA = 8;
const int TYPE_NPCDATA = 9;
const int TYPE_COMBODATA = 10;
const int TYPE_SPRITEDATA = 11;
const int TYPE_SHOPDATA = 12;
const int TYPE_MAPDATA = 13;

void RunInstruction()
{
	switch(STACK[SP])
	{
		case FASTTILE: 
		{
			Screen->FastTile(GetArg(), GetArg(), GetArg(), GetArg(), GetArg(), GetArg()); 
			break;
		}
	}
}

//Advances a line in the instruction list.
// CR(list[q], 64)
// q = CR(q,64);
int CR(int pos, int linewidth) 
{
	return pos - pos%linewidth + linewidth;

int GetArg()
{
	int indx = count;
	CVT = VARTYPES[count];
	++count;
	int rv;
	switch(CVT) //which array to use
	{
		case TYPE_GLOBAL;
		{
			rv = G[indx]; break;
		}
		case TYPE_INT:
		{
			rv = I[indx]; break;
		}
		case TYPE_NPC:
		{
			rv = N[indx]; break;
		}
		case TYPE_LWEAPON:
		{
			rv = L[indx]; break;
		}
		case TYPE_EWEAPON:
		{
			rv = E[indx]; break;
		}
		case TYPE_FFC:
		{
			rv = F[indx]; break;
		}
		case TYPE_ITEM:
		{
			rv = IT[indx]; break;
		}
		case TYPE_ITEMDATA:
		{
			rv = ID[indx]; break;
		}
		case TYPE_NPCDATA:
		{
			rv = ND[indx]; break;
		}
		case TYPE_COMBODATA:
		{
			rv = CD[indx]; break;
		}
		case TYPE_SPRITEDATA:
		{
			rv = WD[indx]; break;
		}
		case TYPE_SHOPDATA:
		{
			rv = SD[indx]; break;
		}
		case TYPE_MAPDATA:
		{
			rv = MD[indx]; break;
		}
		default: 
		{
				TraceS("Invalid datatype supplied to GetArg()");
				break;
		}
	}
	return rv;
}

//sets the arg value to any type of array
void SetArg(int val)
{
	int indx = count;
	CVT = VARTYPES[count];
	++count;
	int rv;
	switch(CVT) //which array to use
	{
		case TYPE_GLOBAL;
		{
			G[indx] = Untype(val) = Untype(val); break;
		}
		case TYPE_INT:
		{
			I[indx] = Untype(val); break;
		}
		case TYPE_NPC:
		{
			N[indx] = Untype(val); break;
		}
		case TYPE_LWEAPON:
		{
			L[indx] = Untype(val); break;
		}
		case TYPE_EWEAPON:
		{
			E[indx] = Untype(val); break;
		}
		case TYPE_FFC:
		{
			F[indx] = Untype(val); break;
		}
		case TYPE_ITEM:
		{
			IT[indx] = Untype(val); break;
		}
		case TYPE_ITEMDATA:
		{
			ID[indx] = Untype(val); break;
		}
		case TYPE_NPCDATA:
		{
			ND[indx] = Untype(val); break;
		}
		case TYPE_COMBODATA:
		{
			CD[indx] = Untype(val); break;
		}
		case TYPE_SPRITEDATA:
		{
			WD[indx] = Untype(val); break;
		}
		case TYPE_SHOPDATA:
		{
			SD[indx] = Untype(val); break;
		}
		case TYPE_MAPDATA:
		{
			MD[indx] = Untype(val); break;
		}
		default: 
		{
				TraceS("Invalid datatype supplied to GetArg()");
				break;
		}
	}
}


//NEWER functions to extract a var value from a token.
//gets the array ID (type) and index ID of the array

int _GetVar(int token, int pos) if ( IdentifyVar(token,0)) return GetVarValue(); return 0; }

int IdentifyVar(int w, int pos)
{
	
		
	int v[5]; //varid[3]; 1024
	int type[3]; //type 2
	int len = strlen(w)-1;
	if ( len > 7 ) return false;
	int temp = CVL;
	int vartype;
	//copy only the type to this array
	for ( ; temp <= len; ++temp )
	{
		if ( IsNumber(w[temp]) )
		{
			v[temp] = w[temp];
			continue;
		}
		if ( IsAlpha(w[temp]) )
		{
			v[temp] = w[temp];
			continue;
		}
	}
	if ( strcmp(v, "G") ) vartype = TYPE_GLOBAL;
	else if ( strcmp(v, "I") ) vartype =  TYPE_INT;
	else if ( strcmp(v, "N") ) vartype =  TYPE_NPC;
	else if ( strcmp(v, "L") ) vartype =  TYPE_LWEAPON;
	else if ( strcmp(v, "E") ) vartype =  TYPE_EWEAPON;
	else if ( strcmp(v, "F") ) vartype =  TYPE_FFC;
	else if ( strcmp(v, "IT") ) vartype =  TYPE_ITEM;
	else if ( strcmp(v, "ID") ) vartype =  TYPE_ITEMDATA;
	else if ( strcmp(v, "ND") ) vartype =  TYPE_NPCDATA;
	else if ( strcmp(v, "CD") ) vartype =  TYPE_COMBODATA;
	else if ( strcmp(v, "WD") ) vartype =  TYPE_SPRITEDATA;
	else if ( strcmp(v, "SD") ) vartype =  TYPE_SHOPDATA;
	else if ( strcmp(v, "MD") ) vartype =  TYPE_MAPDATA;
	else { vartype = TYPE_WTF; TraceNL(); TracS("Illegal vartype found by IdentifyVar()"); return false;}
	
	CVL = 0; //clear
	
	int id = itoa(v);
	ZBASIC[0] = vartype; ZBASIC[1] = id;
	return true;
}	

int GetVarValue();
{	int type = ZBASIC[0];
	int indx = ZBASIC[1];
	int rv;
	switch(type) //which array to use
	{
		case TYPE_GLOBAL;
		{
			rv = G[indx]; break;
		}
		case TYPE_INT:
		{
			rv = I[indx]; break;
		}
		case TYPE_NPC:
		{
			rv = N[indx]; break;
		}
		case TYPE_LWEAPON:
		{
			rv = L[indx]; break;
		}
		case TYPE_EWEAPON:
		{
			rv = E[indx]; break;
		}
		case TYPE_FFC:
		{
			rv = F[indx]; break;
		}
		case TYPE_ITEM:
		{
			rv = IT[indx]; break;
		}
		case TYPE_ITEMDATA:
		{
			rv = ID[indx]; break;
		}
		case TYPE_NPCDATA:
		{
			rv = ND[indx]; break;
		}
		case TYPE_COMBODATA:
		{
			rv = CD[indx]; break;
		}
		case TYPE_SPRITEDATA:
		{
			rv = WD[indx]; break;
		}
		case TYPE_SHOPDATA:
		{
			rv = SD[indx]; break;
		}
		default:
		{
			rv = 0;
			TraceNL();
			TraceS("GetVarValue() encountered an invalid var array type"); 
			TraceNL();
			break
		}
		
		
	}
	ZBASIC[0] = 0;
	ZBASIC[1] = 0;
	return rv;
	
}

//this stores the ID when lexing. Parsing uses the literal stored to the script RAM.
//We could store this directly on the stack, but I would rather have 100 scripts with 1024 max
//instructions each, that we can copy to the stack when they run.

//but then, we would need a mechanism to store al of the values used by scripts when they complete execution.
//Grr... That'd be faster, but it would eat quite a lot of array space.

//Otherwise, we interpret the scripts each time before execution. No JIT here. :P
int GetInstruction(int word)
{
	/* Would it be faster to do an incremental pattern match?
	//Probably not?
	int wordsize = strlen(word);
	int words[]=
	{
		list each command one at time
		each on its own line
		shortest to longest.
		
		pattern match begins at a specified word size?
		
	}
	*/
	
	if ( strcmp(word, "FastTile" ) return FASTTILE;
}

//determines the type of array to use
int ExtractVarType(int w)
{
	/*
	int types[]=
	"
		G //global
		I //int
		N //npc
		L //lweapon
		E //eweapon
		It //item
		F //ffc
		ID //itemdata
		ND //npcdata
		CD //combodata
		WD //spritedata
		SD //shopdata
		MD //mapdata
	";
	*/
		
	int v[3]; //vartype[3];
	int len = strlen(w)-1;
	int temp;
	//copy only the type to this array
	for ( ; temp < 2; ++temp )
	{
		if ( !IsNumber(w[temp]) )
		{
			v[temp] = w[temp];
		}
	}
	
	CVL = temp; //set the length of this var,
	//we'll need it for speeding uo extracting its 
	//literal value
	
	if ( strcmp(v, "G") ) return TYPE_GLOBAL;
	if ( strcmp(v, "I") ) return TYPE_INT;
	if ( strcmp(v, "N") ) return TYPE_NPC;
	if ( strcmp(v, "L") ) return TYPE_LWEAPON;
	if ( strcmp(v, "E") ) return TYPE_EWEAPON;
	if ( strcmp(v, "F") ) return TYPE_FFC;
	if ( strcmp(v, "IT") ) return TYPE_ITEM;
	if ( strcmp(v, "ID") ) return TYPE_ITEMDATA;
	if ( strcmp(v, "ND") ) return TYPE_NPCDATA;
	if ( strcmp(v, "CD") ) return TYPE_COMBODATA;
	if ( strcmp(v, "WD") ) return TYPE_SPRITEDATA;
	if ( strcmp(v, "SD") ) return TYPE_SHOPDATA;
	if ( strcmp(v, "MD") ) return TYPE_MAPDATA;
	
	I //item
		F //ffc
		ID //itemdata
		ND //npcdata
		CD //combodata
		WD //spritedata
		SD //shopdata
	
}	
		


//gets the index ID of the array
int ExtractVarID(int w)
{
	
		
	int v[5]; //vartype[3];
	int len = strlen(w)-1;
	int temp = CVL;
	//copy only the type to this array
	for ( ; temp <= len; ++temp )
	{
		if ( IsNumber(w[temp]) )
		{
			v[temp] = w[temp];
		}
	}
	
	CVL = 0; //clear
	
	int id = itoa(v);
	return id;
}	

//determines the type of array to use
int ExtractVarType(int w)
{
	/*
	int types[]=
	"
		G //global
		I //int
		N //npc
		L //lweapon
		E //eweapon
		It //item
		F //ffc
		ID //itemdata
		ND //npcdata
		CD //combodata
		WD //spritedata
		SD //shopdata
		MD //mapdata
	";
	*/
		
	int v[3]; //vartype[3];
	int len = strlen(w)-1;
	int temp;
	//copy only the type to this array
	for ( ; temp < 2; ++temp )
	{
		if ( !IsNumber(w[temp]) )
		{
			v[temp] = w[temp];
		}
	}
	
	CVL = temp; //set the length of this var,
	//we'll need it for speeding uo extracting its 
	//literal value
	
	if ( strcmp(v, "G") ) return TYPE_GLOBAL;
	if ( strcmp(v, "I") ) return TYPE_INT;
	if ( strcmp(v, "N") ) return TYPE_NPC;
	if ( strcmp(v, "L") ) return TYPE_LWEAPON;
	if ( strcmp(v, "E") ) return TYPE_EWEAPON;
	if ( strcmp(v, "F") ) return TYPE_FFC;
	if ( strcmp(v, "IT") ) return TYPE_ITEM;
	if ( strcmp(v, "ID") ) return TYPE_ITEMDATA;
	if ( strcmp(v, "ND") ) return TYPE_NPCDATA;
	if ( strcmp(v, "CD") ) return TYPE_COMBODATA;
	if ( strcmp(v, "WD") ) return TYPE_SPRITEDATA;
	if ( strcmp(v, "SD") ) return TYPE_SHOPDATA;
	if ( strcmp(v, "MD") ) return TYPE_MAPDATA;
	
	I //item
		F //ffc
		ID //itemdata
		ND //npcdata
		CD //combodata
		WD //spritedata
		SD //shopdata
	
}	
		

int GetVarValue(int type, int indx);
{
	int rv;
	switch(type) //which array to use
	{
		case TYPE_GLOBAL;
		{
			rv = G[indx]; break;
		}
		case TYPE_INT:
		{
			rv = I[indx]; break;
		}
		case TYPE_NPC:
		{
			rv = N[indx]; break;
		}
		case TYPE_LWEAPON:
		{
			rv = L[indx]; break;
		}
		case TYPE_EWEAPON:
		{
			rv = E[indx]; break;
		}
		case TYPE_FFC:
		{
			rv = F[indx]; break;
		}
		case TYPE_ITEM:
		{
			rv = IT[indx]; break;
		}
		case TYPE_ITEMDATA:
		{
			rv = ID[indx]; break;
		}
		case TYPE_NPCDATA:
		{
			rv = ND[indx]; break;
		}
		case TYPE_COMBODATA:
		{
			rv = CD[indx]; break;
		}
		case TYPE_SPRITEDATA:
		{
			rv = WD[indx]; break;
		}
		case TYPE_SHOPDATA:
		{
			rv = SD[indx]; break;
		}
		
	}
	return rv;
	
}

//stores an instruction string into WORD[] when parsing the script, 
int GetInstrString(int word)
{
	int buf[64];
	int sz = strlen(word) -1;
	int temp; bool n; bool token; int q; int paramID;
	for ( ; temp < sz; ++temp )
	{
		//if we find a token before an instruction, exit and report false?
		if ( IsParsingToken(word[q]) continue; //return 0; //break;
		
		//! ...but we need to store tokens onto their own tempstack!!
		if ( IsNumber(word[q]) ) continue; //ignore line numbers and all numerals
		if ( word[q] == ' ' ) continue; //eat WS
		if ( !word[q] ) break; //halt on str term.
		buf[q] = word[q];
	}
	for ( q = 0; q < 64; ++q )
	{
		//tore label into the global word buffer.
		WORD[q] = buf[q];
	}
	
	//! Here we must also store the param values, or any assigns.
	
	//Find the instruction parame
	// We continue to scan, starting at temp:
	int param[64]; int scope;
	do
	{
		
		for ( ; temp < sz; ++temp )
		{
			if ( word[temp] == ' ' ) continue; //eat WS
			//open scope and copy
			if ( word[temp] == '(' )
			{
				do
				{
					++temp;
					if ( word[temp] == ' ' ) continue; //eat WS
					if ( word[temp] == '(' ) 
					{
						++scope;
						continue;
					}
					
					if ( word[temp] == ')'
					{
						--scope;
						continue;
					}
					param[temp] = word[temp];
				}
				while(scope <= 0);
			}
			
			//determine if param is an expression
			
			//if it is:
				//1. Copy it to the EXPRESSION array.
				//2 resolve i
				//store its litral value
			
			//id not, it's a var or a literal
			
			//extract the vallue and move on
			
			//inrement param, so that we can know how many of them we store
			//is this at all useful?
			
			++paramID;
			
			
			SetArg(atof(param)); //param must be resolved if an expression, so we might need another buffer
		}
		while(word[temp] != ';'); //look for the next param, or $END
	}
		
		
		
	
			
		
	
	/*
	
	This also needs to be in the expression checker.
	
	Assigns in the language will be enclosed by braces or parens
	or some special token.
	
		[I26 = 90;] 
	
		Do we need array sntax?
	
	This way, the parser knows that it is about to encounter a variable?
	
	//or shyould we just enclose variables?
	
	Perhaps @var_id?
	
	@G26 = 70
	
	One positive note, is that assign and expr during a function call would work.
	
	
	*/
	
	
}
		
float ExpressionChecker(int word)
{
	int rv;
	//convert vars to literals and store
	//store script literals and store
	//store operation signs
	
	//determine operation ordering
	//resolvng scopes
	
	//process expression
	
	//Functions aere in the fake ffc 'class' expr.
	//call as expr.f()
	
	return rv;
	
}




void Parse()
{
	int inistack = curstack;
	SP = 0;
	//scan each line 
	//prune line number
	prune leading spaces
	//store the text of this line until '(' or 'other tokenm,
		//such as '=' to WORD[]
	if the operator is a maths sign, or a token
		that modifies a var immediately
	UPDATE GLOBAL VARS
	then do the maths here
		store the param:
		1. if a literal, copy the char to PARAM
			then
			CPV = ftoa(PARAM);
		2. otherwise, it's a var:
			read the identifier to VARIABLE[]
			scan the type ID first
		
		//nO, SCREW THAT.
		//Use an UNTYPED array, and we won't need to care about datatypes!
		Otherwise...
		
		CVT = ExtractVarType(PARAM);
		VARTYPES[CSR] = CVT;
		
		
		//extract the param *value* next
		
		//SCRIPTRAM[CSR] = ;
		SetArg(CVT,GetvarValue(CVT,ExtractVarID(PARAM)));
		//now the value of that variable is set and ready to execute
		//with Getparam().
	repeat for next param.
		
	run :
	++SP; STACK[SP] = GetInstruction(WORD);
	
		
}

/*

THis wuld allow for truly generic processing of instructions. 
Any internal instruction would simply use getArg() to get
the value assignd to it. 

The parser would not know if there are insufficient parameters
aimed at an instruction, but we could determine this during lexing...

The user could assign values to these, and a set of predefined 
scripts to edit.


/*

//Expressions

/*
1. While there are still tokens to be read in,
   1.1 Get the next token.
   1.2 If the token is:
       1.2.1 A number: push it onto the value stack.
       1.2.2 A variable: get its value, and push onto the value stack.
       1.2.3 A left parenthesis: push it onto the operator stack.
       1.2.4 A right parenthesis:
         1 While the thing on top of the operator stack is not a 
           left parenthesis,
             1 Pop the operator from the operator stack.
             2 Pop the value stack twice, getting two operands.
             3 Apply the operator to the operands, in the correct order.
             4 Push the result onto the value stack.
         2 Pop the left parenthesis from the operator stack, and discard it.
       1.2.5 An operator (call it thisOp):
         1 While the operator stack is not empty, and the top thing on the
           operator stack has the same or greater precedence as thisOp,
           1 Pop the operator from the operator stack.
           2 Pop the value stack twice, getting two operands.
           3 Apply the operator to the operands, in the correct order.
           4 Push the result onto the value stack.
         2 Push thisOp onto the operator stack.
2. While the operator stack is not empty,
    1 Pop the operator from the operator stack.
    2 Pop the value stack twice, getting two operands.
    3 Apply the operator to the operands, in the correct order.
    4 Push the result onto the value stack.
3. At this point the operator stack should be empty, and the value
   stack should have only one value in it, which is the final result.
   
  */
  
ffc script expr
{
	void run(){}
	//int precedence(int op) { return Precedence(op); }
	//int applyOp(int a, int b, int op) { return ApplyOp(a, b, op); }
	
	
	// Function to find precedence of 
	// operators.
	int Precedence(int op)
	{
		if (op == '+') return 1;
		if ( op == '-') return 1;
		if (op == '*') return 2;
		if ( op == '/') return 2;
		if ( op }== '^') return 3;
		return 0;
	}
	 
	// Function to perform arithmetic operations.
	int ApplyOp(int a, int b, int op){
		switch(op)
		{
			case '+': { return a + b; }
			case '-': { return a - b; }
			case '*': { return a * b; }
			case '/': { return a / b; }
			case '^'; { return Pow(a,b); } //No bitwise Xor in Z.Basic. 
		}
	}
}


	/* Parens
	Parens increase precedence by ++ per paren.
	Work similar to scope in other functions.
	*/

	int FindScopePrecedence(int token, int pos)
	{
		int len = strlen(token);
		int scope; int tempscope;
		do
		{
			if ( token[pos] == '(' ) { ++scope; ++tempscope;
			if ( token[pos] == ')' ) --tempscope;
		} while ( tempscope > 0 );
		return scope;
	}

/*
**Find highest precedence from scopes?
**define scopes
Store all values and ops in a temp array
Store precedence of each
Find all types with precedence 
Apply ordr 2 precedence to val, then clear the value, and operator from a temp list, setting operator to -1.
Repeat for precedence 1
then 0.
*/
	}

// CPP program to evaluate a given
// expression where tokens are 
// separated by space.
//#include <bits/stdc++.h>
//using namespace std;
 

int DoExpr(int word)
{
	int inistack = curstack;
	int buf[1024]; int q; bool foundop; bool sign;
	int number[14]; bool foundvalue; bool foundnum; bool foundvar;
	int len = SizeOfArray(word);
	int varid[4];
	for ( q = 0; q < len; ++q ) buf[q] = word[q];
	int place = 0;
	++q; buf[q] = 0; //terminate
	q = -1;
	while(reading)
	{
		++q;
		
		//look for numbers before an operator
		if ( !foundop && !foundvalue )
			//first value can be signed
		{
			if ( buf[q] == ' '; ) //eat WS
				continue;
			
			if ( buf[q] == '-' ) { sign = true; ++q; }
			//read the number portion of the string into a value.
			//numbers only
			
			while ( IsNumber(buf[q]) || buf[q] == '.' ) 
			{
				foundnum = true;
				if ( buf[q] == '.' ) 
				{
					if ( !dec )
					{
						dec = true;
						number[place] = buf[q]];
						++place;
					}
					else continue;
				}
				else
				{
					number[place] = buf[q];
					++place;
				}
			}
			
			if ( foundnum ) //it isn't a var, but a literal
			{
				if ( sign ) { sign = false; val = atof(number)*-1;  }//store the extracted value.
				else val = atof(number); //store the extracted value.
				foundvalue = true;
			}
			//variables
			if ( !foundnum ) //is it a variable?
			{
				bool seeking = true;
				while(seeking)
				{
					if ( buf[q] == 'I' ) { foundvar = true; seeking = false; break; }
					else if ( buf[q] == 'N' ) { foundvar = true; seeking = false; break; }
					else if ( buf[q] == 'L' ) { foundvar = true; seeking = false; break; }
					else if ( buf[q] == 'E' ) { foundvar = true; seeking = false; break; }
					else if ( buf[q] == 'F' ) { foundvar = true; seeking = false; break; }
					else if ( buf[q] == 'C' ) { foundvar = true; seeking = false; break; }
					else if ( buf[q] == 'W' ) { foundvar = true; seeking = false; break; }
					else if ( buf[q] == 'S' ) { foundvar = true; seeking = false; break; }
					else if ( buf[q] == '<' ) { foundvar = true; seeking = false; break; }
					else break;
				}
				if ( foundvar ) //found it, so extract it.
				{
					for ( int w = q; w < q+2; ++w )
					{
						varid[w] = buf[q+w];
					}
					int vartype = ExtractVarType(varid);
					int indx = ExtractVarID(varid);
					val = GetVarValue(vartype,indx);
					foundvalue = true;
				}
					
			}
				
		}
		if ( foundvalue ) 
		//push value here
		stack.change(OPERAND);
		stack.push(val);
		
		// 1.2.3 A left parenthesis: push it onto the operator stack.
     
      
		//loop for a lparen
		if ( buf[q] == '(' ) 
		{
			//push the paren to operators
			stack.change(OPERATORS);
			stack.push('(');
		}
		
		//  1.2.4 A right parenthesis:
		if ( buf[q] == ')' ) 
		{
			/*
			1 While the thing on top of the operator stack is not a 
		   left parenthesis,
		     1 Pop the operator from the operator stack.
		     2 Pop the value stack twice, getting two operands.
		     3 Apply the operator to the operands, in the correct order.
		     4 Push the result onto the value stack.
		 2 Pop the left parenthesis from the operator stack, and discard it.
			*/
		}
		
		
		/*
		
	       1.2.5 An operator (call it thisOp):
		 1 While the operator stack is not empty, and the top thing on the
		   operator stack has the same or greater precedence as thisOp,
		   1 Pop the operator from the operator stack.
		//stack.change(OPERATOR);
		//stack.pop(INX1);
		   2 Pop the value stack twice, getting two operands.
		//
		// stack.change(OPERAND).
		// stack.pop(EXPR2);
		// stack.pop(EXPR1);
		   3 Apply the operator to the operands, in the correct order.
		   4 Push the result onto the value stack.
		//stack.push(EXPR2);
		 2 Push thisOp onto the operator stack.
	2. While the operator stack is not empty,
	    1 Pop the operator from the operator stack.
	    2 Pop the value stack twice, getting two operands.
	    3 Apply the operator to the operands, in the correct order.
	    4 Push the result onto the value stack.
	3. At this point the operator stack should be empty, and the value
	   stack should have only one value in it, which is the final result.
   */
		
		if ( !foundop && foundvalue )
			//the next thing must be an operator
		{
			if ( buf[q] == ' '; ) //eat WS
				continue;
			
			if ( IsOperator(buf[q] ) 
			{
				//push it and its precedence
				foundop = true;
			}
			
		}
	}
}
			
				
/*
 Convert Infix Expression to Post-Fix Expression

Conventional notation is called infix notation. The arithmetic operators appears between two operands. Parentheses are required to specify the order of the operations. For example: a + (b * c).
Post fix notation (also, known as reverse Polish notation) eliminates the need for parentheses. There are no precedence rules to learn, and parenthese are never needed. Because of this simplicity, some popular hand-held calculators use postfix notation to avoid the complications of multiple sets of parentheses. The operator is placed directly after the two operands it needs to apply. For example: a b c * +
This short example makes the move from infix to postfix intuitive. However, as expressions get more complicated, there will have to be rules to follow to get the correct result:
 

Simple heuristic algorithm to visually convert infix to postfix

 •  Fully parenthesize the expression, to reflect correct operator precedence 
 •  Move each operator to replace the right parenthesis to which it belongs 
 •  Remove paretheses 
 
Evaluating expressions

A stack is used in two phases of evaluating an expression such as 

       3 * 2 + 4 * (A + B) 
•Convert the infix form to postfix using a stack to store operators and then pop them in correct order of precedence. 
•Evaluate the postfix expression by using a stack to store operands and then pop them when an operator is reached. 
Infix to postfix conversion
Scan through an expression, getting one token at a time. 

1 Fix a priority level for each operator. For example, from high to low: 

    3.    - (unary negation)
    2.    * /
    1.    + - (subtraction)
Thus, high priority corresponds to high number in the table. 

2 If the token is an operand, do not stack it. Pass it to the output. 

3 If token is an operator or parenthesis, do the following: 

   -- Pop the stack until you find a symbol of lower priority number than the current one. An incoming left parenthesis will be considered to have higher priority than any other symbol. A left parenthesis on the stack will not be removed unless an incoming right parenthesis is found. 
The popped stack elements will be written to output. 

   --Stack the current symbol. 
   -- If a right parenthesis is the current symbol, pop the stack down to (and including) the first left parenthesis. Write all the symbols except the left parenthesis to the output (i.e. write the operators to the output). 

   -- After the last token is read, pop the remainder of the stack and write any symbol (except left parenthesis) to output. 
Example: 
Convert A * (B + C) * D to postfix notation. 

Move
Curren Ttoken
Stack
Output 
1
A
empty
A
2
*
*
A
3
(
(*
A
4
B
(*
A B
5
+
+(*
A B
6
C
+(*
A B C
7
)
*
A B C +
8
*
*
A B C + *
9
D
*
A B C + * D
10

empty
 
Notes: 
In this table, the stack grows toward the left. Thus, the top of the stack is the leftmost symbol. 
In move 3, the left paren was pushed without popping the * because * had a lower priority then "(". 
In move 5, "+" was pushed without popping "(" because you never pop a left parenthesis until you get an incoming right parenthesis. In other words, there is a distinction between incoming priority, which is very high for a "(", and instack priority, which is lower than any operator. 
In move 7, the incoming right parenthesis caused the "+" and "(" to be popped but only the "+" as written out. 
In move 8, the current "*" had equal priority to the "*" on the stack. So the "*" on the stack was popped, and the incoming "*" was pushed onto the stack. 
 
Evaluating Postfix Expressions

Once an expression has been converted to postfix notation it is evaluated using a stack to store the operands. 
   
•  Step through the expression from left to right, getting one token at a time. 
•  Whenever the token is an operand, stack the operand in the order encountered. 
•  When an operator is encountered: 
•  If the operator is binary, then pop the stack twice 
•  If the operator is unary (e.g. unary minus), pop once 
•  Perform the indicated operation on the operator(s) 
•  Push the result back on the stack. 
•  At the end of the expression, the top of the stack will have the correct value for the expression. 

Example:

Evaluate the expression 2 3 4 + * 5 * which was created by the previous algorithm for infix to postfix. 

Move
Current Token
Stack (grows toward left)
1
2
 
2
2
3
 
3 2
3
4
 
4 3 2
4
+
 
7 2
5
*
 
14
6
5
 
5 14
7
*
 
70
Notes: 
Move 4: an operator is encountered, so 4 and 3 are popped, summed, then pushed back onto stack. 
Move 5: operator * is current token, so 7 and 2 are popped, multiplied, pushed back onto stack. 
Move 7: stack top holds correct value. 
Notice that the postfix notation has been created to properly reflect operator precedence. Thus, postfix expressions never need parentheses. 
 
 
 
 */


//Another implementation...

public static double eval(final String str) {
    return new Object() {
        int pos = -1, ch;

        void nextChar() {
            ch = (++pos < str.length()) ? str.charAt(pos) : -1;
        }

        boolean eat(int charToEat) {
            while (ch == ' ') nextChar();
            if (ch == charToEat) {
                nextChar();
                return true;
            }
            return false;
        }

        double parse() {
            nextChar();
            double x = parseExpression();
            if (pos < str.length()) throw new RuntimeException("Unexpected: " + (char)ch);
            return x;
        }

        // Grammar:
        // expression = term | expression `+` term | expression `-` term
        // term = factor | term `*` factor | term `/` factor
        // factor = `+` factor | `-` factor | `(` expression `)`
        //        | number | functionName factor | factor `^` factor

        double parseExpression() {
            double x = parseTerm();
            for (;;) {
                if      (eat('+')) x += parseTerm(); // addition
                else if (eat('-')) x -= parseTerm(); // subtraction
                else return x;
            }
        }

        double parseTerm() {
            double x = parseFactor();
            for (;;) {
                if      (eat('*')) x *= parseFactor(); // multiplication
                else if (eat('/')) x /= parseFactor(); // division
                else return x;
            }
        }
int VAR[4];
int word[]
int temp;
        double parseFactor() {
            if (eat('+')) return parseFactor(); // unary plus
            if (eat('-')) return -parseFactor(); // unary minus

            double x;
            int startPos = this.pos;
            if (eat('(')) { // parentheses
                x = parseExpression();
                eat(')');
            } else if ((ch >= '0' && ch <= '9') || ch == '.') { // numbers
                while ((ch >= '0' && ch <= '9') || ch == '.') nextChar();
                x = Double.parseDouble(str.substring(startPos, this.pos));
            } else if (ch >= 'a' && ch <= 'z') { // vars
		    temp = 0;
                while (ch != ' ') {
			var[temp] = ch;
			nextChar();
		}
		//if ( vartype = IdentifyVar(var,0) ) varvalue = GetVarValue();
		
                String func = str.substring(startPos, this.pos);
                x = parseFactor();
                if (func.equals("sqrt")) x = Math.sqrt(x);
                else if (func.equals("sin")) x = Math.sin(Math.toRadians(x));
                else if (func.equals("cos")) x = Math.cos(Math.toRadians(x));
                else if (func.equals("tan")) x = Math.tan(Math.toRadians(x));
                else throw new RuntimeException("Unknown function: " + func);
            } else {
                throw new RuntimeException("Unexpected: " + (char)ch);
            }

            if (eat('^')) x = Math.pow(x, parseFactor()); // exponentiation

            return x;
        }
    }.parse();
}