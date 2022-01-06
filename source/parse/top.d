module parse.top;

import parse.core;
import parse.top;
import parse.terminal;
import parse.node;

import ast;
import tools;
import symbols;

import std.stdio;
import std.format;
import std.sumtype;
import std.algorithm;


Statement[] parseGlobal() {
    // mixin errorPass;

    Statement[] scop;
    while (1) {
        consumeWhitespace();
        if (file.eof()) break;
        statementClosed = false;
        scop ~= parseStatement;
        // else
        //     assert(0);
    }
    return scop;
}

Statement parseStatement() {
   return parseExpression.unwrap;
}


Result!(SumType!Expression) parseExpression() {
    mixin errorPass;
    alias Sum = SumType!Expression;

    template CHECK(alias fn) {
        enum CHECK = q{{auto val = %s; if (val.isOk)
            return ok(Sum(val.unwrap));
        }}.format(fn.stringof);
    }
    mixin (CHECK!parseInt);
    mixin (CHECK!parseString);
    mixin (CHECK!parseVariable);
    mixin (CHECK!parseScope);
    //*/
    return err!"Expression err";
}