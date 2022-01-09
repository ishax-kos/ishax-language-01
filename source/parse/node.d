module parse.node;

import parse.core;
import parse.terminal;

import ast;
import tools;
import symbols;

import std.stdio;
import std.format;
import std.sumtype;
import std.algorithm;




Result!Variable parseVariable() {
    mixin errorPass;
    Variable var;
    {auto name = parseIdentifier(); 
        if (name.isOk) {
            var.symbol = name.unwrap;
        }
        else 
            return err();
    }
    return ok(var);
}


Result!(Scope) parseScope() {
    mixin errorPass;

    static c = 0;
    writefln!":%s"(c++);
    scope(exit) c--;

    if (!parseSym!"{".isOk)
        return err!"Missing open bracket.";

    Scope scop;
    // statementClosed = true;

    while (1) {
        import parse.top: parseStatement, checkClosure;
        
        if (parseSym!"}".isOk) break;
        consumeWhitespace;
        assert(!file.eof, "Premature end of file.");
        scop.statements ~= parseStatement();
        if (parseSym!"}".isOk) {
            Return r;
            writeln("A");
            auto stat = scop.statements[$-1];
            writeln("A");
            r.expr(stat);
            writeln("A");
            scop.statements[$-1] = r;
            writeln("A");
            break; 
        }
        assert (checkClosure(), (new Err("Missing semicolon.")).toString);
    }
    closeBracketFlag = true;
    return ok(scop);
}
