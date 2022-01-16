module parse.top;

import parse.core;
import parse.top;
import parse.bottom;
import parse.compound;

import ast;
import tools;
import symbols;

import std.stdio;
import std.format;
import std.sumtype;
import std.algorithm;


Scope parseGlobal() {
    Scope scop;
    // statementClosed = true;
    while (1) {
        if (isEOF) {
            break;
        }
        writeln("st");
        scop.statements ~= [parseStatement];
        assert (checkClosure(), (new Err("Missing semicolon.")).toString);
    }
    
    // assert(statementClosed, (new Err("Missing semicolon at end of file.")).toString);
    return scop;
}

Expression parseStatement() {
    // mixin errorPass;
    // assert(statementClosed, (new Err("Missing semicolon.")).toString);
    // writeln(__FUNCTION__);
    auto st = parseExpression.unwrap;
    
    return st;
}

int checkClosure() {
    enum {
        False,
        Semi,
        Bracket
    }
    if (closeBracketFlag) {
        closeBracketFlag = false;
        return Bracket;
    }
    if (parseSym!";".isOk) return Semi;
    // auto seek = tellPosition();
    return False;
}


Result!(SumType!ExpressionT) parseExpression() {
    mixin errorPass;
    alias Sum = SumType!ExpressionT;

    template CHECK(alias fn) {
        enum CHECK = q{{
        auto val = %s; 
        if (val.isOk)
            return ok(Sum(val.unwrap));
        }}.format(fn.stringof);
    }
    
    mixin (CHECK!parseScope);
    mixin (CHECK!parseInt);
    mixin (CHECK!parseString);
    mixin (CHECK!parseVariable);

    return err!"ExpressionT err";
}