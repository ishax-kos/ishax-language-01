module parse.core;
import tools;
import ast;
import std.stdio;
import std.format;
import std.typecons: tuple;
import symbols;



// class Node {
//     Node[] children;
// }
// alias Result = bool;

/+~~~~~~~~Internal State~~~~~~~~+/
File* file;
char lastChar = ' ';
Statement[] global;
// Statement tree;
Object parent;
/+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+/


File* loadSource(T)(T location) {
    return new File(location, "rb");
}


alias Result = Object;
enum Result_value = "new Object()";
// enum Result {
//     none,
//     value
// }

/// macro
string parseOrErr(string func)() {
    /++     
        Calls func(state). If func is false, 
        (meaning it hit an error in the source) 
        it propagates that error by returning false. 
        Otherwise it does not return 
    +/
    return `if (` ~ func ~ `()) {}
    else mixin(FAILURE);`;
}


size_t tellPosition() {
    import std.exception;
    
    size_t pos;
    try {
        pos = file.tell();
    }
    catch (ErrnoException e) {
        writeln("ftell failure");
        return -2;
    }
    // writefln("file seek position is %s.", pos);
    return pos;
}


enum FAILURE = q{{
    if (seek == 0) {
        lastChar = 'e'; 
        file.seek(0);
    }
    else {
        assert(seek > 0, "index %s is out of range.".format(seek));
        writefln("...return to %s, line %s", seek, currentLine);
        file.seek(seek-1);
        popChar();
    }
    while (lineStack.front.offset > seek) {
        currentLine -= 1;
        lineStack.removeFront();
    }
    static if (__traits(compiles, lastCall)) {
        lastCall = seek;
    }
    // static if (__traits(compiles, {typeof(return).init;})) 
        return typeof(return).init;
    // else return null;
    
}};


void consumeWhitespace() {
    import std.uni: isWhite;
    while (isWhite(lastChar)) popChar();
}

import std.container: SList;
import std.typecons: Tuple;

uint currentLine = 1;
struct NewLine {uint line; size_t offset;}
SList!NewLine lineStack;
static this() {
    lineStack.insertFront(NewLine(1, 0));
}

void popChar() {
    char[1] b;
    file.rawRead(b);
    if (file.eof) {
        lastChar = '\x00';
        return;
    }
    if (b == "\n") lineStack.insertFront(NewLine(++currentLine, file.tell()));
    lastChar = b[0];
}

bool[string] keywords;
static this() {
    keywords = [
    	"if":0,
    	"then":0,
    	"else":0,
    	"stdout":0
	];
}


Result parseGlobal() {
    ptrdiff_t seek = tellPosition();
    // writeln("  begin: -", lastChar, "-");

    // mixin(parseOrErr!`parseStatement`);
    // mixin(parseOrErr!`parseStatement`);  

    while (!parseEOF()) {
        if (Statement result = parseStatement()) {
            if (!parse!";") mixin(FAILURE);
            global ~= result;
        }
        else assert(0);
    }
    return mixin(Result_value); 
}


Statement parseStatement() {
    if (auto res = parseExpression) return res;
    assert(0, `Invalid sequence at line %s.`.format(lineStack.front.line));
}


Expression parseExpression() {
    ptrdiff_t seek = tellPosition();
    writeln("  expr: ");
    // ptrdiff_t seek = tellPosition();
    if (Declaration res = parseDeclare) return res;
    if (Assignment res = parseAssign) return res;
    if (auto res = parseVarExpr()) return res;
    if (auto res = parseNumLit()) return new Expression();
    mixin(FAILURE);
}


Assignment parseAssign() {
    ptrdiff_t seek = tellPosition();
    static bool lockMe = false;
    writeln("  assign: ");
    if (lockMe) {
        writeln("...locked");
        mixin(FAILURE);
    }
    auto ass = new Assignment();
    {
        lockMe = true;
        scope(exit) lockMe = false;
        if (auto exp = parseExpression()) 
            ass.lhs = exp; // lhs  // tree
        else mixin(FAILURE);
    }
    if (!parse!"=") 
        mixin(FAILURE);
    if (auto exp = parseExpression) 
        ass.rhs = exp; // rhs  // tree 
    else mixin(FAILURE);
    return new Assignment();
}


Expression parseVarInit() {
    writeln("  declare: ");
    ptrdiff_t seek = tellPosition();
    writeln(lastChar);
    mixin(parseOrErr!`parseExpression`); // tree
    mixin(parseOrErr!`parse!";"`);
    return new Expression();
}


FuncLiteral parseFuncLiteral() {
    writeln("  function: ");
    ptrdiff_t seek = tellPosition();
    if (!parse!"(") 
        mixin(FAILURE);

    // Declaration[] args;
    // while (1) {
    //     if (parse!")") break;
    //     if (parseEOF) assert(0, "Premature end of file.");
    //     if (auto res = parseDeclare) args ~= res;
    // }
    if (!parse!")") 
        mixin(FAILURE);
    
    FuncLiteral fun = new FuncLiteral(
        new Declaration[0],
        parseScope()[]
    );
    return fun;
}


Declaration parseDeclare() {
    writeln("  declare: ");
    ptrdiff_t seek = tellPosition();
    if (!parse!":") mixin(FAILURE);
    Declaration decla;
    if (auto name = parseIdentifier)
        decla = new Declaration(name);
    else mixin(FAILURE);

    // writeln("hee");
    /// No explicit init
    if (parse!";") return decla;
    // writeln("ho");
    /// Data init
    if (auto exp = parseExpression) {
        decla.initial = exp;
        return decla;
    }
    else mixin(FAILURE);
}


Result parseOutput() {
    writeln("  to stdio: ");
    ptrdiff_t seek = tellPosition();
    mixin(parseOrErr!`parse!"stdout"`);
    mixin(parseOrErr!`parse!"="`);
    mixin(parseOrErr!`parseExpression`);
    mixin(parseOrErr!`parse!";"`);
    return mixin(Result_value);
}


Ref!string parseIdentifier() {
    writeln("  identifier: ");
    import std.uni: isLower, isAlphaNum;
    ptrdiff_t seek = tellPosition();
    
    consumeWhitespace();

    if (lastChar.isLower()) {}
    else mixin(FAILURE);

    string identifierStr = [cast(char) lastChar]; 
    
    while (1) {
        // write(lastChar);
        popChar();
        if (!isAlphaNum(lastChar)) {
            // writeln("-", cast(uint)lastChar, "-");
            break;
        }
        identifierStr ~= lastChar;
    }

    if (identifierStr in keywords) mixin(FAILURE);

    writeln(identifierStr);
    
    return new Ref!string(identifierStr); /// node with identifier string
}


bool parse(string str)() {
    /// parse sepcific symbols and identifiers
    writefln("  symbol(%s)", str);
    ptrdiff_t seek = tellPosition();

    consumeWhitespace();

    if (lastChar == str[0]) {}
    else mixin(FAILURE);

    size_t i = 0;
    while (1) {
        // write(lastChar);
        popChar();
        if (++i>=str.length || lastChar != str[i]) {
            // writeln("-", cast(uint)lastChar, "-");
            break;
        }
    }

    // writefln("(%s)", str);
    return true;
}


Result parseNumLit() {
    writeln("  number: ");
    ptrdiff_t seek = tellPosition();
    
    consumeWhitespace();

    bool isNum(dchar ch) {
        return (ch >= '0' && ch <= '9');
    }

    /// Test first digit
    if (isNum(lastChar)) {}
    else mixin(FAILURE);

    string numStr = ""; 
    
    while (1) {
        // write(lastChar);
        numStr ~= cast(char) lastChar;
        popChar();
        if (!isNum(lastChar)) {
            // writeln("-", cast(uint)lastChar, "-");
            break;
        }
    }

    writeln(numStr);
    import std.conv: convStr = parse;
    numStr.convStr!int;

    return mixin(Result_value); /// node with identifier string
}


bool parseEOF() {
    consumeWhitespace();
    return file.eof;
}


alias Scope = Statement[];
Ref!Scope parseScope() {
    writeln("  scope: ");
    ptrdiff_t seek = tellPosition();
    
    if(!parse!"{") mixin(FAILURE);

    Ref!Scope scope_ = new Ref!Scope(new Statement[0]);

    while (1) {
        if (parse!"}") return scope_;
        if (parseEOF) assert(0, "Premature end of file.");
        if (auto res = parseStatement) scope_ ~= res;
    }
}


VarExpr parseVarExpr() {
    ptrdiff_t seek = tellPosition();
    auto var = new VarExpr();
    if (auto name = parseIdentifier()) {
        var.name.require(cast(string) name);
    } else mixin(FAILURE);

    return var;
}

unittest {
    file = loadSource("code/test.dn");
    // assert(cast(string)parseIdentifier() == "myFoe");
    assert(parseGlobal);
}