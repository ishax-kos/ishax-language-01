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

    if (!parseSym!"{".isOk)
        return err!"Missing open bracket.";

    Scope scope_;

    while (1) {
        import parse.top: parseStatement;
        
        if (parseSym!"}".isOk) break;
        consumeWhitespace;
        if (file.eof) assert(0, "Premature end of file.");
        scope_.statements ~= parseStatement();
    }
    return ok(scope_);
}