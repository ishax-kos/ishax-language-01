module ast;
import tools;
import std.stdio;
import symbols;

import std.format : format;
import std.range : repeat;
import std.conv : to;
import std.array : array, join;
import std.meta;


alias Type = bool;

string[] getTab(string[] strList) {
    import std.algorithm;
    import std.range;

    return strList.map!(a => ("  " ~ a))().array;
}

string[] getTabArray(T)(T exList) {
    import std.algorithm;
    import std.range;

    string[][] list = exList.map!(a => a.toLines).array;
    return list.join.getTab;
}


string[] toLines(Expression val) {
    return val.match!(
        (v) => v.toLines
    )();
}

string[] toLines(Unit u) {
    return ["[nil]"];
}


mixin template ExprState() {
    Type returnType;

    string[] toLines() {
        return [typeid(this).to!string];
    }

    string toString() {
        return this.toLines.join('\n');
    }
}

// alias Statement = SumType!StatementT;
// alias StatementT = NoDuplicates!(
//     ExpressionT,
//     Return
// );

/+~~~~Expressions~~~~+/

alias Expression = SumType!ExpressionT;
alias ExpressionT = NoDuplicates!(AliasSeq!(
    // Declaration, 
    // Assignment,
    // BinaryOp,
    // FuncLiteral,
    Variable,
    // IfExpr,
    // CallExpr,
    Scope,
    IntegerLit,
    StringLit,
    Return
    ));


struct Return {
    mixin ExprState;
    private Expression* _expr = new Expression;
    Expression expr() {return *_expr;}
    void expr(Expression ex) {*_expr = ex;}
}


struct Variable {
    mixin ExprState;
    string symbol;
    string[] toLines() {
        return ["var: " ~ symbol];
    }
}

struct IntegerLit {
    mixin ExprState;
    long value;
    string[] toLines() {
        return ["lit: "~value.to!string];
    }
}

struct StringLit {
    mixin ExprState;
    string value;
    string[] toLines() {
        return ["lit: \""~value~'\"'];
    }
}

struct Scope {
    mixin ExprState;
    Expression[] statements;

    string[] toLines() {
        import std.algorithm : map;

        // string[] argsStr;
        // foreach (a; args) argsStr ~= a.to!string;
        return ["scope:"] ~
            getTab(statements);
    }
}



// struct IfExpr {
//     mixin ExprState;
//     ExpressionT condition;
//     Scope ifTrue;
//     Scope ifFalse;

//     string[] toLines() {
//         // string s = "if:\n" ~
//         // getTab("condition:\n" ~getTab(condition,2)) ~
//         // getTab("then:\n" ~ifTrue.map!(a=>getTab(a,2)).array.join);
//         // if (ifFalse.length > 0)
//         // s ~= getTab("else:\n"~ifFalse.map!(a=>getTab(a,2)).array.join);
        
//         return ["if"] ~
//             getTab(["condition"] ~ getTab([condition])) ~
//             getTab(["then"] ~ getTab([ifTrue])) ~
//             getTab(["else"] ~ getTab([ifFalse]));
//     }
// }

// struct Declaration {
//     mixin ExprState;
//     string name;
//     Type type;
//     Option!ExpressionT initial;
//     this(string str) {
//         name = str;
//     }

//     string[] toLines() {
//         return "def:" ~
//             getTab(
//                 ("name: " ~ name) ~
//                     initial.tryLines
//             );
//     }
// }

// struct Assignment {
//     mixin ExprState;
//     Option!ExpressionT lhs;
//     Option!ExpressionT rhs;
// }

// struct BinaryOp(string op) {
//     mixin ExprState;
// }

// struct FuncLiteral {
//     mixin ExprState;
//     Declaration[] args;
//     Scope scop;
//     this(typeof(args) args_, typeof(scop) scop_) {
//         args = args_;
//         scop = scop_;
//     }

//     string[] toLines() {
//         import std.algorithm : map;

//         // string[] argsStr;
//         // foreach (a; args) argsStr ~= a.to!string;
//         return (
//             ["func:"] ~
//             getTab(
//                 ["args:"] ~
//                 getTab(args) ~
//                 scop.toLines
//             )
//         );
//     }
// }


// struct CallExpr {
//     mixin ExprState;
//     ExpressionT caller;
//     ExpressionT[] args;
// }

// //*/