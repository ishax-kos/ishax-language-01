module ast;
import tools;
import option;
import symbols;

import std.format: format;
import std.range: repeat;
import std.conv: to;

uint indent = 0;

string getTab() {
    return " ".repeat(indent * 4).to!string;
}

class Expression : Statement {
    Unit returnType;
}


class Declaration : Expression {
    string name;
    Option!bool type;
    Expression initial;
    this(string str) {name = str;}

    override 
    string toString () {
        indent += 1;
        scope(exit) indent -= 1;
        // auto ind = getTab;
        return "definition: %s %s %s".format(type, name, initial);
    }
}

class Assignment : Expression {
    Expression lhs;
    Expression rhs;
}



interface Statement {}


interface Terminal {}


/// Expressions

class BinaryOp(string op) : Expression {}
class FuncLiteral : Expression {
    Declaration[] args;
    Statement[] scop;
    this (typeof(args) args_, typeof(scop) scop_) 
        {args=args_; scop=scop_;}
    override
    string toString() {
        indent += 1;
        scope(exit) indent -= 1;
        auto ind = getTab;
        // return (ind~"(%(%s, %)) {%(%s;\n%)\n}").format(args, scop);
        return "%s, %s".format(args, scop);
    }
}
class CallExpr : Expression {}
class VarExpr : Expression, Terminal {
    Symbol name;
}
class StringLit : Expression, Terminal {}
class NumLit : Expression, Terminal {}