module parse;
import tools;
import ast;
import std.stdio;
import std.format;


// class Node {
//     Node[] children;
// }
// alias Result = bool;

/+~~~~~~~~Internal State~~~~~~~~+/
File* file;
char lastChar = ' ';
Statement[] global;
// Statement tree;
Object Parent;
/+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+/

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
        lastChar = ' '; 
        file.seek(0);
    }
    else {
        assert(seek > 0, "index %s is out of range.".format(seek));
        writefln("...return to %s, line %s", seek, currentLine);
        file.seek(seek); 
        popChar();
    }
    while (lineStack.front.offset > seek) {
        currentLine -= 1;
        lineStack.removeFront();
    }
    return null;
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
    ptrdiff_t seek = tellPosition()-1;
    // writeln("  begin: -", lastChar, "-");

    // mixin(parseOrErr!`parseStatement`);
    // mixin(parseOrErr!`parseStatement`);  
    Result isEof;
    while (1) {
        isEof = parseEOF();
        if (isEof) break;
        parseStatement();
        if (Statement result = parseStatement())
            global ~= result;
        else assert(0);
    }
    return mixin(Result_value);
}


Statement parseStatement() {
    ptrdiff_t seek = tellPosition()-1;
    if (Assignment res = parseAssign) return res;
    if (Declaration res = parseDeclare) return res;
    stderr.writeln(`Invalid sequence at line `, lineStack.front.line,`.`); 
    // mixin(FAILURE);
    assert(0);
}


Result parseExpression() {
    writeln("  expr: ");
    // ptrdiff_t seek = tellPosition()-1;
    if (auto res = parseIdentifier()) return res;
    if (auto res = parseNumber()) return res;
    return null;
}


Assignment parseAssign() {
    writeln("  assign: ");
    ptrdiff_t seek = tellPosition()-1;
    mixin(parseOrErr!`parseExpression`); // lhs  // tree
    mixin(parseOrErr!`parse!"="`);
    mixin(parseOrErr!`parseExpression`); // rhs  // tree
    mixin(parseOrErr!`parse!";"`);
    return new Assignment();
}


Result parseVarInit() {
    writeln("  declare: ");
    ptrdiff_t seek = tellPosition()-1;
    // mixin(parseOrErr!`parse!":"`);
    // mixin(parseOrErr!`parseIdentifier`);
    // if (parse!";") {}
    // else {
    writeln(lastChar);
    mixin(parseOrErr!`parseExpression`); // tree
    mixin(parseOrErr!`parse!";"`);
    // }
    return mixin(Result_value);
}


Result parseFuncInit() {
    writeln("  function: ");
    ptrdiff_t seek = tellPosition()-1;
    // mixin(parseOrErr!`parse!":"`);
    // mixin(parseOrErr!`parseIdentifier`);
    mixin(parseOrErr!`parse!"("`);
        // mixin(parseOrErr!`parseVarDecl`);
    mixin(parseOrErr!`parse!")"`);
    // mixin(parseOrErr!`parse!"{"`);
    
    mixin(parseOrErr!`parseScope`);

    // mixin(parseOrErr!`parse!"}"`);
    return mixin(Result_value);
}


Declaration parseDeclare() {
    writeln("  declare: ");
    ptrdiff_t seek = tellPosition()-1;
    mixin(parseOrErr!`parse!":"`);
    mixin(parseOrErr!`parseIdentifier`);
    /// No explicit init
    if (parse!";") return new Declaration();
    
    /// Data init
    if (parseVarInit) return new Declaration();

    /// Function Init
    if (parseFuncInit) return new Declaration();
    
    assert(0, "invalid init");
    
}


Result parseOutput() {
    writeln("  to stdio: ");
    ptrdiff_t seek = tellPosition()-1;
    mixin(parseOrErr!`parse!"stdout"`);
    mixin(parseOrErr!`parse!"="`);
    mixin(parseOrErr!`parseExpression`);
    mixin(parseOrErr!`parse!";"`);
    return mixin(Result_value);
}


Result parseIdentifier() {
    writeln("  identifier: ");
    import std.uni: isLower, isAlphaNum;
    ptrdiff_t seek = tellPosition()-1;
    
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

    return mixin(Result_value); /// node with identifier string
}


Result parse(string str)() {
    /// parse sepcific symbols and identifiers
    writefln("  symbol(%s)", str);
    ptrdiff_t seek = tellPosition()-1;

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
    return mixin(Result_value);
}


Result parseNumber() {
    writeln("  number: ");
    ptrdiff_t seek = tellPosition()-1;
    
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


Result parseEOF() {
    consumeWhitespace();
    if (file.eof) return mixin(Result_value);
    else return null;
}


Result parseScope() {
    writeln("  scope: ");
    ptrdiff_t seek = tellPosition()-1;
    
    mixin(parseOrErr!`parse!"{"`);

    Statement[] thisScope;

    while (1) {
        if (parse!"}") return thisScope;
        if (res = parseStatement) thisScope ~= res;
    }
    mixin(FAILURE);
}

// Result parseStatement() {

// }