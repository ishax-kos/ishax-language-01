module parse.terminal;

import parse.core;
import ast;
import tools;

import std.stdio;
import std.format;
import std.sumtype;
import std.algorithm;


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
    if (keywords.canFind(identifierStr))
        return err();

    return ok(identifierStr); /// node with identifier string
}

Result!Unit parseSym(string str)() {
    /// parse specific symbols
    mixin errorPass;

    // static if (str == ";") {
    //     parseSym!"}";
    // }

    consumeWhitespace();

    size_t i = 0;
    while (i < str.length) {
        if (lastChar != str[i]) break;
        popChar(); ++i;
    }

    // writefln("(%s)", str);
    return ok(nil);
}


Result!Unit parseKey(string str)() {
    import std.uni : isLower, isAlphaNum;
    /// parse specific keywords
    mixin errorPass;
    static assert(keywords.canFind(str));
    consumeWhitespace();
    size_t i = 0;
    while (i < str.length) {
        if (lastChar != str[i]) return err!"keyword not found.";
        popChar(); ++i;
    }
    if (lastChar.isAlphaNum) return err!"keyword doesn't terminate.";
    return ok(nil);
}


Result!IntegerLit parseInt() {
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
        if (!isNum(lastChar)) break;
    }

    writeln(numStr);
    import std.conv : convStr = parse;
    auto lit = IntegerLit();
    lit.value = numStr.convStr!long;
    return ok(lit);
}


// Result!Unit parseNotEOF() {
//     mixin errorPass;
//     consumeWhitespace();
//     if (file.eof) return ok(nil);
//     else return err!"end of file reached";
// }


Result!StringLit parseString() {
    mixin errorPass;

    consumeWhitespace();
    if (lastChar != '"') return err();
    popChar();
    auto str = StringLit();
    
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