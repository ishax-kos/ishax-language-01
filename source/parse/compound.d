module parse.compound;

import parse.core;
import parse.terminal;

import ast;
import tools;
import symbols;
import parse.top: parseExpression;

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


Result!Scope parseScope() {
    mixin errorPass;


    if (!parseSym!"{".isOk)
        return err("Missing open bracket.");

    Scope scop;
    // statementClosed = true;

    while (1) {
        import parse.top: parseIsStatement;
        
        if (parseSym!"}".isOk) break;
        consumeWhitespace;
        assert(!file.eof, "Premature end of file.");
        auto st = parseExpression.unwrap;

        if (parseSym!"}".isOk) {
            scop.statements ~= Expression(Return(st));
            break; 
        }
        else {
            scop.statements ~= st.parseIsStatement;
        }
        
    }
    // closeBracketFlag = true;
    return ok(scop);
}


Result!Declaration parseDeclare() {
    mixin errorPass;
        if (parseSym!":/".isErr) /// Redefine
            if (parseSym!":".isErr) 
                return err("'"~lastChar~"' found instead of ':'");
    Declaration decla;
    decla.name = parseIdentifier.unwrap();
	
    decla.initial = parseExpression.match!(
        (Expression e) => e.match!(
            function Expression*(Declaration _) {assert(0, "Nested declarations are not allowed.");},
            (_) {
                auto exPtr = new Expression();
                *exPtr = e;
                return exPtr;
            },
        ),
        (Err _) => null,
    );


    return ok(decla);
}


Result!FuncLiteral parseFuncLiteral() {
    mixin errorPass;
    FuncLiteral fun;
    if (parseSym!"(".isErr) return err("Open parentheses not found.");
    
    if (parseSym!")".isErr)
    while (1) {
        auto dec = parseDeclare;
        if (dec.isOk) fun.args ~= dec.unwrap;
        // else return err("");

        if (parseSym!")".isOk) break;
        else assert(parseSym!",".isOk, new Err("Missing separator.").toString);
    }

    Result!Scope scop = parseScope();

    if (scop.isErr) {
        return passErr(scop);
    }

    fun.scop = new Scope();
    *fun.scop = scop.unwrap;

    return ok(fun);
}


Result!CallExpr parseCall() {
    mixin errorPass;
    CallExpr call;//writeln("A");

    static lock = false;
    if (lock) return err("recurse");
    // writefln!":%s"(c++);
    // scope(exit) c--;

    // if (!parse!("*")) return err();
    
    Result!Expression caller;
    {
        lock = true;
        scope(exit) lock = false;
        caller = parseType!(LValueNodes,FuncLiteral);
    }

    if (caller.isOk) 
        // if (caller.unwrap.isT!(LValueNodes,FuncLiteral)) 
            call.caller = caller.unwrap;
        // else return err("Not callable.");
    else return err();
    
    if (parseSym!("(").isErr) return err("Call has no parentheses.");
    
    if (parseSym!")".isErr)
    while (1) {
        call.args ~= parseExpression().unwrap;

        if (parseSym!")".isOk) break;
        else assert(parseSym!",".isOk, new Err("Missing separator.").toString);
    }
        // if (auto arg = ) 
        //     call.args ~= arg;
        // else return err();
    
    return ok(call);
}



Result!Expression parseType(T...)() {
    mixin errorPass;
    auto lvalue = parseExpression;
    if (lvalue.isOk) 
        if (lvalue.unwrap.isT!(T)) 
            return lvalue;
        else return err("wrong type");
    else return err();
}


Result!IfExpr parseIfElse() {
    mixin errorPass;
    IfExpr ifex;
    
    if(parseKey!"if".isErr) {return err();}
    bool neg = parseSym!"!".isOk;

    parseSym!"(".unwrap;
    ifex.condition = parseExpression.unwrap;
    parseSym!")".unwrap;

    ifex.ifTrue = parseScope.unwrap;

    auto elseRes = parseKey!"else";
    auto elseScope = parseScope;
    if (elseScope.isErr) {
        if (elseRes.isOk) 
            return err("Dangling 'else' keyword.");}
    else {
        ifex.ifFalse = elseScope.unwrap();}

    return ok(ifex);
}


Result!Assignment parseAssign() {
    mixin errorPass;
    Assignment assn;

    if (parseKey!"mutate".isErr) return err();
    assn.lhs = parseType!(LValueNodes).unwrap;
    parseSym!",".unwrap;
    assn.rhs = parseExpression.unwrap;

    return ok(assn);
}