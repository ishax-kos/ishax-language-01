module ast;
import tools;
import std.stdio;
import symbols;

import std.format : format;
import std.range : repeat;
import std.conv : to;
import std.array : array, join;

alias Type = bool;

string[] getTab(string[] strList) {
    import std.algorithm;
    import std.range;

    return strList.map!(a => ("  " ~ a))().array;
}

string[] getTab(T)(T[] strList) {
    import std.algorithm;
    import std.range;

    string[][] list = strList.map!(a => a.toLines).array;
    return list.join.getTab;
}

class Expression : Statement {
    Type returnType;

    override
    string[] toLines() {
        return [typeid(this).to!string];
    }

    override
    string toString() {
        return this.toLines.join('\n');
    }
}

class Declaration : Expression {
    string name;
    Type type;
    Expression initial;
    this(string str) {
        name = str;
    }

    override
    string[] toLines() {
        return "def:" ~
            getTab(
                ("name: " ~ name) ~
                    (initial ? initial.toLines : ["null"])
            );
    }
}

class Assignment : Expression {
    Expression lhs;
    Expression rhs;
}

interface Statement {

    string[] toLines();

    // Unit codegen();
}

interface Terminal {
}

/// Expressions

class BinaryOp(string op) : Expression {
}

class FuncLiteral : Expression {
    Declaration[] args;
    Scope scop;
    this(typeof(args) args_, typeof(scop) scop_) {
        args = args_;
        scop = scop_;
    }

    override
    string[] toLines() {
        import std.algorithm : map;

        // string[] argsStr;
        // foreach (a; args) argsStr ~= a.to!string;
        return (
            ["func:"] ~
            getTab(
                ["args:"] ~
                getTab(args) ~
                scop.toLines
            )
        );
    }
}

class VarExpr : Expression, Terminal {
    Symbol symbol;
    override string[] toLines() {
        return [symbol.name];
    }
}

class IfExpr : Expression {
    Expression condition;
    Scope ifTrue;
    Scope ifFalse;

    override
    string[] toLines() {
        // string s = "if:\n" ~
        // getTab("condition:\n" ~getTab(condition,2)) ~
        // getTab("then:\n" ~ifTrue.map!(a=>getTab(a,2)).array.join);
        // if (ifFalse.length > 0)
        // s ~= getTab("else:\n"~ifFalse.map!(a=>getTab(a,2)).array.join);
        
        return ["if"] ~
            getTab(["condition"] ~ getTab([condition])) ~
            getTab(["then"] ~ getTab([ifTrue])) ~
            getTab(["else"] ~ getTab([ifFalse]));
    }
}

class CallExpr : Expression {
    Expression caller;
    Expression[] args;
}

class Scope : Expression {
    Statement[] statements;

    override
    string[] toLines() {
        import std.algorithm : map;

        // string[] argsStr;
        // foreach (a; args) argsStr ~= a.to!string;
        return ["scope:"] ~
            getTab(statements);
    }
}

class IntegerLit : Expression, Terminal {
    long value;
}

class StringLit : Expression, Terminal {
    string value;
    // this(string str){
    //     value=str;
    // }
}
