module parse;

import tools;
import ast;
import terminal;

import std.stdio;
import std.format;
import std.sumtype;
import std.container : SList;
import std.typecons : Tuple, tuple;
import std.conv;
/+~~~~~/+~~~Internal State~~~+/~~~~~+/
File* file;
char lastChar = ' ';
Object parent;
/+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+/

File* loadSource(T)(T location) {
    return new File(location, "rb");
}


class Err {
    string msg;
    ptrdiff_t line;
    ptrdiff_t col;
    this(string msg) {
        this.msg = msg;
        line = currentLine; col = currentCol;
    }

    override
    string toString() {
        return format!"Error at %s/%s: %s"(line, col, msg);
    }
}


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


alias Result(T...) = SumType!(T, Err);

T pass(T)(T val) {return val;}
T errorOut(T)(Err e) {assert(0, e.to!string);}

mixin template errorPass() {
    import std.traits;
    
    ptrdiff_t seek = tellPosition();
    private alias Res = typeof(return);
    static assert (__traits(isSame, SumType, TemplateOf!(typeof(return))));
    static assert (TemplateArgsOf!(typeof(return)).length == 2);
    static assert (is(TemplateArgsOf!(typeof(return))[$-1] == Err));
        // ); 
        // {
        private alias RetT = TemplateArgsOf!(typeof(return))[0];


        Res err(string msg = "Unnamed error.")() {
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
            return Res(new Err(msg));
        }


        Res ok(T)(T val = null) if(__traits(compiles, typeof(return)(val))) {
            return Res(val);
        }
}

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
    // mixin errorPass;

    Statement[] scop;
    while (1) {
        consumeWhitespace();
        if (file.eof()) break;
        if (Statement result = parseStatement()) {
            scop ~= result;
        }
        else
            assert(0);
    }
    return scop;
}

Statement parseStatement() {
    return parseString.match!(
        pass!StringLit,
        errorOut!StringLit
    )();
}


// parseTerminal


unittest {
    file = loadSource("code/main.dn");
    // assert(cast(string)parseIdentifier() == "myFoe");
    auto ast = parseGlobal;
    assert(ast);
    writefln!"%(%s\n%)"(ast);
}
