module parse.core;
import tools;
import ast;
import std.stdio;
import std.format;
import symbols;
import std.container : SList;
import std.typecons : Tuple, tuple;
import std.conv;
 
 
// class Node {
//     Node[] children;
// }
// alias Result = bool;
 
/+~~~~~/+~~~Internal State~~~+/~~~~~+/
File* file;
char lastChar = ' ';
Object parent;
/+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+/

File* loadSource(T)(T location)
{
    return new File(location, "rb");
}

// alias Result = Object;
enum Result_value = "new Object()";
// enum Result {
//     none,
//     value
// }

/// macro
string parseOrErr(string func)()
{
    /++     
        Calls func(state). If func is false, 
        (meaning it hit an error in the source) 
        it propagates that error by returning false. 
        Otherwise it does not return 
    +/
    return `if (` ~ func ~ `()) {}
    else mixin(failure(null));`;
}

size_t tellPosition()
{
    import std.exception;

    size_t pos;
    try
    {
        pos = file.tell();
    }
    catch (ErrnoException e)
    {
        writeln("ftell failure");
        return -2;
    }
    //*** writefln("file seek position is %s.", pos);
    return pos;
}

string failure(T)(T ret)
{
    return `{` ~ q{
    	//errPos = seek;
        if (seek == 0) {
            lastChar = 'e'; 
            file.seek(0);
        }
        else {
            assert(seek > 0, "index %s is out of range.".format(seek));
            // writefln("...return to %s, line %s", seek, currentLine);
            file.seek(seek-1);
            popChar();
        }
        while (lineStack.front > seek) {
            currentLine -= 1;
            lineStack.removeFront();
        }
        return }
        ~ ret.text ~ `;` ~
        `}`;
}

void consumeWhitespace()
{
    import std.uni : isWhite;

    while (isWhite(lastChar))
        popChar();
}


size_t currentLine = 1;
//size_t errPos = 1;
SList!size_t lineStack;
static this()
{
    lineStack.insertFront(0);
}


size_t currentCol() {
	return file.tell() - lineStack.front();
}


void popChar()
{
    char[1] b;
    file.rawRead(b);
    if (file.eof)
    {
        lastChar = '\x00';
        return;
    }
    if (b == "\n")
    {
        lineStack.insertFront(file.tell());
        currentLine += 1;
    }
    lastChar = b[0];
}

bool[string] keywords;
static this()
{
    keywords = [
        "if": 0,
        "then": 0,
        "else": 0,
        "stdout": 0
    ];
}

Statement[] parseGlobal()
{
    ptrdiff_t seek = tellPosition();
    // //writeln("  begin: -", lastChar, "-");

    // mixin(parseOrErr!`parseStatement`);
    // mixin(parseOrErr!`parseStatement`);  
    Statement[] scop;
    while (!parseEOF())
    {
        if (Statement result = parseStatement())
        {
            scop ~= result;
        }
        else
            assert(0);
    }
    return scop;
}

Statement parseStatement()
{
    if (auto res = parseExpression)
    {
        //assert(parse!";", format!"Missing semicolon at line %s/%s."(
        	//currentLine,currentCol));
        return res;
    }
    assert(0, format!"Invalid sequence at line %s/%s."(
    	currentLine,currentCol));
}

Expression parseExpression()
{
    ptrdiff_t seek = tellPosition();
    //writeln("  expr: ");
    // ptrdiff_t seek = tellPosition();
    if (auto res = parseIfElse()) return res;
    if (Declaration res = parseDeclare) return res;
    if (Assignment res = parseAssign) return res;
    if (auto res = parseVarExpr()) return res;
    if (auto res = parseNumLit()) return new Expression();
    if (auto res = parseFuncLiteral()) return res;
    mixin(failure(null));
}

Assignment parseAssign()
{
    ptrdiff_t seek = tellPosition();
    static bool lockMe = false;
    //writeln("  assign: ");
    if (lockMe)
    {
        //writeln("...locked");
        mixin(failure(null));
    }
    auto ass = new Assignment();
    //{
        //lockMe = true;
        //scope (exit)
            //lockMe = false;
        //if (auto exp = parseExpression())
            //ass.lhs = exp; // lhs  // tree
        //else
            //mixin(failure(null));
    //}
    if (!parse!"set")
        mixin(failure(null));
    
    if (auto exp = parseExpression())
        ass.lhs = exp; // lhs  // tree
    else
        mixin(failure(null));
        
    if (auto exp = parseExpression)
        ass.rhs = exp; // rhs  // tree 
    else
        mixin(failure(null));
    return new Assignment();
}

Expression parseVarInit()
{
    //writeln("  declare: ");
    ptrdiff_t seek = tellPosition();
    writeln(lastChar);
    mixin(parseOrErr!`parseExpression`); // tree
    return new Expression();
}

FuncLiteral parseFuncLiteral()
{
    //writeln("  function: ");
    ptrdiff_t seek = tellPosition();
    //if (!parse!"(")
        //mixin(failure(null));

    Declaration[] args;
    if (parse!"(") {
		while (auto res = parseDeclare)
		{
			args ~= res;	
		}
		if (!parse!")")
	         mixin(failure(null));
	}
	else if (!parse!"&")
	         mixin(failure(null));

    FuncLiteral fun = new FuncLiteral(
        args,
        parseScope().inside
    );
    return fun;
}

Declaration parseDeclare()
{
    //writeln("  declare: ");
    ptrdiff_t seek = tellPosition();
     if (!parse!";")
         mixin(failure(null));
    Declaration decla;
    if (auto name = parseIdentifier)
        decla = new Declaration(name);
    else
        mixin(failure(null));
	
	if (parse!"=") {
	    if (auto exp = parseExpression) {
	        decla.initial = exp;
	    } 
	    else mixin(failure(null));
    }
	//else if (!parse!";") mixin(failure(null));
    
    return decla;
}

// void parseOutput() {
//     //writeln("  to stdio: ");
//     ptrdiff_t seek = tellPosition();
//     mixin(parseOrErr!`parse!"stdout"`);
//     mixin(parseOrErr!`parse!"="`);
//     mixin(parseOrErr!`parseExpression`);
//     return mixin(Result_value);
// }

Ref!string parseIdentifier()
{
    //writeln("  identifier: ");
    import std.uni : isLower, isAlphaNum;

    ptrdiff_t seek = tellPosition();

    consumeWhitespace();

    if (lastChar.isLower())
    {
    }
    else
        mixin(failure(null));

    string identifierStr = [cast(char) lastChar];

    while (1)
    {
        // write(lastChar);
        popChar();
        if (!isAlphaNum(lastChar))
        {
            // writeln("-", cast(uint)lastChar, "-");
            break;
        }
        identifierStr ~= lastChar;
    }

    if (identifierStr in keywords)
        mixin(failure(null));

    // writeln(identifierStr);

    return new Ref!string(identifierStr); /// node with identifier string
}

bool parse(string str)()
{
    /// parse sepcific symbols and identifiers
    //writefln("  symbol(%s)", str);
    ptrdiff_t seek = tellPosition();

    consumeWhitespace();

    if (lastChar == str[0])
    {
    }
    else
        mixin(failure(false));

    size_t i = 0;
    while (1)
    {
        // write(lastChar);
        popChar();
        if (++i >= str.length || lastChar != str[i])
        {
            // writeln("-", cast(uint)lastChar, "-");
            break;
        }
    }

    // writefln("(%s)", str);
    return true;
}

Ref!long parseNumLit()
{
    //writeln("  number: ");
    ptrdiff_t seek = tellPosition();

    consumeWhitespace();

    bool isNum(dchar ch)
    {
        return (ch >= '0' && ch <= '9'); 
    }

    /// Test first digit
    if (isNum(lastChar))
    {
    }
    else
        mixin(failure(null));

    string numStr = "";

    while (1)
    {
        // write(lastChar);
        numStr ~= cast(char) lastChar;
        popChar();
        if (!isNum(lastChar))
        {
            // writeln("-", cast(uint)lastChar, "-");
            break;
        }
    }

    // writeln(numStr);
    import std.conv : convStr = parse;

    return new Ref!long(numStr.convStr!long);
}

bool parseEOF()
{
    consumeWhitespace();
    return file.eof;
}

alias Scope = Statement[];
Ref!Scope parseScope()
{
    //writeln("  scope: ");
    ptrdiff_t seek = tellPosition();

    if (!parse!"{")
        mixin(failure(null));

    Ref!Scope scope_ = new Ref!Scope(new Scope(0));

    while (1)
    {
        if (parse!"}") {
            return scope_;
        }
        if (parseEOF)
            assert(0, "Premature end of file.");
        if (auto res = parseStatement)
            scope_ ~= res;
    }

}

VarExpr parseVarExpr()
{
    ptrdiff_t seek = tellPosition();
    auto var = new VarExpr();
    if (auto name = parseIdentifier())
    {
        var.name.require(cast(string) name);
    }
    else
        mixin(failure(null));

    return var;
}



IfExpr parseIfElse()
{
    ptrdiff_t seek = tellPosition();
    auto ifex = new IfExpr();
    
    if (!parse!"if"()) mixin(failure(null));
    
	bool neg = false;
    if (!parse!"!"()) neg = true;
    
    if (!parse!"("()) mixin(failure(null));
    
    if (auto exp = parseExpression()) {
    	ifex.condition = exp;
    } else mixin(failure(null));
    
    if (!parse!")"()) mixin(failure(null));
    
    if (auto scop = parseScope()) {
    	ifex.ifTrue = scop;
    } else mixin(failure(null));
    
    if (parse!"else") {
	    if (auto scop = parseScope()) {
	    	ifex.ifFalse = scop;
	    } mixin(failure(null));
    }
    else {
	    if (auto scop = parseScope()) {
	    	ifex.ifFalse = scop;
	    }
    }
    

    return ifex;
}


unittest
{
    file = loadSource("code/test.dn");
    // assert(cast(string)parseIdentifier() == "myFoe");
    auto ast = parseGlobal;
    assert(ast);
    writefln!"%(%s\n%)"(ast);
}
