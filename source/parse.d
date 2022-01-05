module parse;
import tools;
import ast;
import std.stdio;
import std.format;
import symbols;
import std.container : SList;
import std.typecons : Tuple, tuple;
import std.conv;
import std.sumtype;
 
/+~~~~~/+~~~Internal State~~~+/~~~~~+/
File* file;
char lastChar = ' ';
Object parent;
/+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+/




File* loadSource(T)(T location) {
    return new File(location, "rb");
}

// alias Result = Object;
enum Result_value = "new Object()";
// enum Result {
//     none,
//     value
// }

/// macro

enum INVALID_SEQUENCE = `assert(0, 
    format!"Invalid sequence at line %s/%s."(currentLine,currentCol)
);`;

size_t tellPosition() {
    import std.exception;

    size_t pos;
    try {
        pos = file.tell();
    }
    catch (ErrnoException e) {
        writeln("ftell err");
        return -2;
    }
    //*** writefln("file seek position is %s.", pos);
    return pos;
}


mixin template errorTrace() {
    ptrdiff_t seek = tellPosition();
    private alias T = typeof(return);
    
    enum string parentName = __traits(identifier, __traits(parent, {}));

    T err(T ret)() {
        // writeln(
        //     format!"Invalid sequence at line %s/%s. %s"(currentLine,currentCol,
        //     parentName)
        // );
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
        return ret;
    }
}

/*
alias Result(T...) = SumType!(Error, T);


mixin template errorTrace() {
    import std.traits;
    ptrdiff_t seek = tellPosition();
    private alias Res = typeof(return);
    private alias RetT = TemplateArgsOf!(typeof(return))[1];
    Res err(string msg = "Unnamed error.") {
    	//errPos = seek;
        if (seek == 0) {
            lastChar = '\0'; 
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
        return Res(new Error(msg));
    }


    Res ok(RetT val) {
        Res(val);
    }
}*/

void consumeWhitespace() {
    import std.uni : isWhite;

    while (isWhite(lastChar))
        popChar();
}


size_t currentLine = 1;
//size_t errPos = 1;
SList!size_t lineStack;
static this() {
    lineStack.insertFront(0);
}


size_t currentCol() {
	return file.tell() - lineStack.front();
}


void popChar() {
    char[1] b;
    file.rawRead(b);
    if (file.eof) {
        lastChar = '\x00';
        return;
    }
    if (b == "\n") {
        lineStack.insertFront(file.tell());
        currentLine += 1;
    }
    lastChar = b[0];
}

bool[string] keywords;
static this() {
    keywords = [
        "if": 0,
        "then": 0,
        "else": 0,
        "stdout": 0
    ];
}

Statement[] parseGlobal() {
    mixin errorTrace;

    Statement[] scop;
    while (!parseEOF()) {
        if (Statement result = parseStatement()) {
            scop ~= result;
        }
        else
            assert(0);
    }
    return scop;
}

Statement parseStatement() {
    // mixin errorTrace;
    if (auto res = parseExpression) {
        //assert(parse!";", format!"Missing semicolon at line %s/%s."(
        	//currentLine,currentCol));
        return res;
    }
    assert(0,
        format!"Invalid sequence at line %s/%s."(currentLine,currentCol)
    );
}

/*Result!
*/Expression parseExpression() {
    mixin errorTrace;
    //writeln("  expr: ");
    // mixin errorTrace;
    if (auto res = parseAssign()) return res;
    if (auto res = parseFuncLiteral()) return res;
    if (auto res = parseDeclare()) return res;
    if (auto res = parseCall()) return res;
    if (auto res = parseVarExpr()) return res;
    if (auto res = parseNumLit()) return res;
    if (auto res = parseStringLit()) return res;
    if (auto res = parseIfElse()) return res;
    return err!null;
}

/*Result!
*/Assignment parseAssign() {
    mixin errorTrace;
    static bool lockMe = false;
    //writeln("  assign: ");
    if (lockMe) {
        //writeln("...locked");
        return err!null;
    }
    auto ass = new Assignment();
    //{
        //lockMe = true;
        //scope (exit)
            //lockMe = false;
        //if (auto exp = parseExpression())
            //ass.lhs = exp; // lhs  // tree
        //else
            //return err!null;
    //}
    if (!parse!"set")
        return err!null;
    
    if (auto exp = parseExpression())
        ass.lhs = exp; // lhs  // tree
    else
        return err!null;
        
    if (auto exp = parseExpression)
        ass.rhs = exp; // rhs  // tree 
    else
        return err!null;
    return new Assignment();
}

/*Result!
*/FuncLiteral parseFuncLiteral() {
    //writeln("  function: ");
    mixin errorTrace;
    //if (!parse!"(")
        //return err!null;

    Declaration[] args;
    if (parse!"(") {
		while (!parse!")") {
            if (auto res = parseDeclare) 
			    args ~= res;
            else mixin(INVALID_SEQUENCE);
		}
	}
	else if (!parse!"&")
	         return err!null;

    FuncLiteral fun = new FuncLiteral(
        args,
        parseScope()
    );
    return fun;
}

/*Result!
*/Declaration parseDeclare() {
    //writeln("  declare: ");
    mixin errorTrace;
     if (!parse!";")
         return err!null;
    Declaration decla;
    if (auto name = parseIdentifier)
        decla = new Declaration(name);
    else
        return err!null;
	
	if (parse!"=") {
	    if (auto exp = parseExpression) {
	        decla.initial = exp;
	    } 
	    else return err!null;
    }
	//else if (!parse!";") return err!null;
    
    return decla;
}

// void parseOutput() {
//     //writeln("  to stdio: ");
//     mixin errorTrace;
//     mixin(parseOrErr!`parse!"stdout"`);
//     mixin(parseOrErr!`parse!"="`);
//     mixin(parseOrErr!`parseExpression`);
//     return mixin(Result_value);
// }

/*Result!
*/string parseIdentifier() {
    //writeln("  identifier: ");
    import std.uni : isLower, isAlphaNum;

    mixin errorTrace;

    consumeWhitespace();

    if (lastChar.isLower()) {
    }
    else
        return err!null;

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

    if (identifierStr in keywords)
        return err!null;

    // writeln(identifierStr);

    return new Ref!string(identifierStr); /// node with identifier string
}

/*Result!
*/bool parse(string str)() {
    /// parse sepcific symbols and identifiers
    //writefln("  symbol(%s)", str);
    mixin errorTrace;

    consumeWhitespace();

    if (lastChar == str[0]) {
    }
    else
        return err!false;

    size_t i = 0;
    while (1) {
        // write(lastChar);
        popChar();
        if (++i >= str.length || lastChar != str[i]) {
            // writeln("-", cast(uint)lastChar, "-");
            break;
        }
    }

    // writefln("(%s)", str);
    return true;
}

/*Result!
*/IntegerLit parseNumLit() {
    //writeln("  number: ");
    mixin errorTrace;

    consumeWhitespace();

    bool isNum(dchar ch) {
        return (ch >= '0' && ch <= '9'); 
    }

    /// Test first digit
    if (!isNum(lastChar)) return err!null;

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

    // writeln(numStr);
    import std.conv : convStr = parse;
    auto lit = new IntegerLit();
    lit.value = numStr.convStr!long;
    return lit;
}

/*Result!
*/bool parseEOF() {
    mixin errorTrace;
    consumeWhitespace();
    if (file.eof) return true;
    else return err!false;
}

/*Result!
*/Scope parseScope() {
    //writeln("  scope: ");
    mixin errorTrace;

    if (!parse!"{")
        return err!null;

    Scope scope_ = new Scope();

    while (1) {
        if (parse!"}") {
            return scope_;
        }
        if (parseEOF)
            assert(0, "Premature end of file.");
        if (auto res = parseStatement)
            scope_.statements ~= res;
    }
}


/*Result!
*/VarExpr parseVarExpr() {
    mixin errorTrace;
    auto var = new VarExpr();
    if (auto name = parseIdentifier()) {
        var.symbol.require(cast(string) name);
    }
    else
        return err!null;

    return var;
}



/*Result!
*/IfExpr parseIfElse() {
    writeln("wee wah");
    mixin errorTrace;
    auto ifex = new IfExpr();
    
    if (!parse!"if"()) return err!null;
    
	bool neg = false;
    if (parse!"!"()) neg = true;
    
    if (!parse!"("()) return err!null;
    
    if (auto exp = parseExpression()) {
    	ifex.condition = exp;
    } else return err!null;
    
    if (!parse!")"()) return err!null;
    
    if (auto scop = parseScope()) {
    	ifex.ifTrue = scop;
    } else return err!null;
    
    if (!parse!"else") 
        return ifex;

    if (auto scop = parseScope()) {
        ifex.ifFalse = scop;
    } else return err!null;

    return ifex;
}


/*Result!
*/CallExpr parseCall() {
    mixin errorTrace;
    auto call = new CallExpr();
    if (!parse!("*")) return err!null;
    if (!parse!("(")) return err!null;
    if (auto caller = parseExpression) call.caller = caller;
    else return err!null;
    while (!parse!(")")) 
        if (auto arg = parseExpression()) 
            call.args ~= arg;
        else mixin(INVALID_SEQUENCE);
    
    return call;
}


/*Result!
*/StringLit parseStringLit() {
    mixin errorTrace;

    consumeWhitespace();
    if (lastChar != '"') return err!null;
    popChar();
    auto str = new StringLit();
    
    while (lastChar != '"') {
        // writeln(lastChar);
        str.value ~= lastChar;
        if (parseEOF()) assert(0);
        popChar();
    }
    popChar();
    // str.value = ("hello world");
    // writeln(str.value);
    return str;
}



unittest {
    file = loadSource("code/main.dn");
    // assert(cast(string)parseIdentifier() == "myFoe");
    auto ast = parseGlobal;
    assert(ast);
    writefln!"%(%s\n%)"(ast);
}
