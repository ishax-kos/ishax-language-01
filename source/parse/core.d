module parse.core;

import tools;
import ast;

import std.stdio;
import std.traits;
import std.format;
import std.sumtype;
import std.container : SList;
import std.typecons : Tuple, tuple;
import std.conv;

/+~~~~~/+~~~Internal State~~~+/~~~~~+/
File* file;
char lastChar = ' ';
bool closeBracketFlag = false;
/+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+/

File* loadSource(T)(T location) {
    return new File(location, "rb");
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


bool look(alias par)() {
    auto seek = tellPosition();
    scope(exit) file.seek(seek-1);
    popChar();
    return par.isOk;
}


mixin template errorPass() {
    // auto dbg = typeid(writeln(__FUNCTION__));
    
    ptrdiff_t seek = tellPosition();
    private alias Res = typeof(return);
    static assert (isResult!(typeof(return)));
    
    private alias RetT = ResultType!(typeof(return));
    enum FNAME = __FUNCTION__;

    Res err() {
        return err!("err in "~FNAME);
    }
    Res err(string msg)() {
        file.seekPop(seek);
        while (lineStack.front > seek) {
            currentLine -= 1;
            lineStack.removeFront();
        }
        return Res(new Err(msg));
    }


    Res ok(T)(T val) if(__traits(compiles, typeof(return)(val))) {
        writefln!"%s %s (%s)"(FNAME, seek, lastChar);
        return Res(val);
    }
}


void seekPop(File* f, ptrdiff_t seek) {
    if (seek == 0) {
        lastChar = '\0';
        f.seek(0);
    }

    else {
        assert(seek > 0, "index %s is out of range.".format(seek));
        f.seek(seek-1);
        popChar();
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


enum string[] keywords = [
    "if",
    "then",
    "else",
    "stdout"
];



alias Result(T) = SumType!(T, Err);


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


T errorOut(T)(Err e) {assert(0, e.to!string);}


auto unwrap(T)(T res) {
    import std.traits;
    alias RetT = TemplateArgsOf!T[0];
    return res.match!(
        errorOut!RetT,
        (v) => v
    )();
}


bool isOk(T)(T res) {
    return res.match!(
        (Err e) => false,
        (_) => true
    )();
}

template isResult(T) {
    enum bool isResult =
        __traits(isSame, SumType, TemplateOf!(T))
        && TemplateArgsOf!(T).length == 2
        && is(TemplateArgsOf!(T)[$-1] == Err);
}


alias ResultType(T) = TemplateArgsOf!T[0];