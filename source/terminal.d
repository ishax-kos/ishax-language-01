module terminal;

import parse;
import ast;
import tools;

import std.stdio;
import std.format;
import std.sumtype;

Result!string parseIdentifier() {
    import std.uni : isLower, isAlphaNum;

    mixin errorPass;

    consumeWhitespace();

    if (lastChar.isLower()) {
    }
    else
        return err();

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
        return err();

    return ok(identifierStr); /// node with identifier string
}

Result!bool parseSym(string str)() {
    /// parse sepcific symbols and identifiers
    //writefln("  symbol(%s)", str);
    mixin errorPass;

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

Result!IntegerLit parseNumLit() {
    //writeln("  number: ");
    mixin errorPass;

    consumeWhitespace();

    bool isNum(dchar ch) {
        return (ch >= '0' && ch <= '9'); 
    }

    /// Test first digit
    if (!isNum(lastChar)) return err();

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
    return ok(lit);
}

Result!Unit parseNotEOF() {
    mixin errorPass;
    consumeWhitespace();
    if (file.eof) return ok();
    else return err!"end of file reached";
}


Result!StringLit parseString() {
    mixin errorPass;

    consumeWhitespace();
    if (lastChar != '"') return err();
    popChar();
    auto str = new StringLit();
    
    while (lastChar != '"') {
        // writeln(lastChar);
        str.value ~= lastChar;
        if (file.eof()) assert(0);
        popChar();
    }
    popChar();
    // str.value = ("hello world");
    // writeln(str.value);
    return ok(str);
}