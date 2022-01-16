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
        scop.statements ~= [parseExpression.unwrap.parseIsStatement];
    }
    
    // assert(statementClosed, (new Err("Missing semicolon at end of file.")).toString);
    return scop;
}


Expression parseIsStatement(Expression expr) {
    enum Sep = ";";
    bool parseSep() {
        return isEOF() || parseSym!Sep.isOk;
    }
    assert (
        expr.match!(
            (Scope _) => true,
            (IfExpr _) => true,
            (_) => parseSep,
        )(),
        (new Err("Missing semicolon.")).toString
    );
    return expr;
}


template CHECK(alias fn) {
    enum CHECK = q{{
    auto val = %1$s; 
    if (val.isOk) {
        writeln("shit_","%1$s");
        return ok(Expression(val.unwrap));
    }
    }}.format(fn.stringof);
}


Result!(SumType!ExpressionT) parseExpression() {
    mixin errorPass;
    
    mixin (CHECK!parseAssign);
    mixin (CHECK!parseIfElse);
    mixin (CHECK!parseCall);
    mixin (CHECK!parseFuncLiteral);
    mixin (CHECK!parseScope);
    mixin (CHECK!parseDeclare);
    mixin (CHECK!parseInt);
    mixin (CHECK!parseString);
    mixin (CHECK!parseVariable);

    return err("Expression err");
}

