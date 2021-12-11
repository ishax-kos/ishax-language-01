module ast;
import tools;
import option;
import symbols;


class Expression : Statement {
    Unit returnType;
}


class Declaration : Expression {
    string name;
    Option!bool type;
    Expression initial;
    this(string str) {name = str;}
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
        {args=args_; scop_=scop;}
}
class CallExpr : Expression {}
class VarExpr : Expression, Terminal {
    Symbol name;
}
class StringLit : Expression, Terminal {}
class NumLit : Expression, Terminal {}