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


mixin template SetGet(T, string name) {
    enum _name = "_"~name;
    mixin("private ",T,"* ",_name,";");
    mixin(
    T,` `, name,`() {
        if (!`,_name,`) `,_name,` = new `,T,`();
        return *`,_name,`;
    }
    void `,name,`(`,T,` ex) {
        if (!`,_name,`) `,_name,` = new `,T,`();
        *`,_name,` = ex;
    }`);
}


/+~~~~Expressions~~~~+/

alias LValueNodes = AliasSeq!(
    Variable
);
alias Expression = SumType!ExpressionT;
alias ExpressionT = NoDuplicates!(AliasSeq!(
    Declaration, 
    Assignment,
    // BinaryOp,
    FuncLiteral,
    Variable,
    IfExpr,
    CallExpr,
    Scope,
    IntegerLit,
    StringLit,
    Return
    ));


struct Return {
    mixin ExprState;
    mixin SetGet!(Expression, "expr");
    this(Expression ex) {expr(ex);}

    string[] toLines() {
        return ["returns: "] ~
            getTabArray([*_expr]);
    }
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
            getTabArray(statements);
    }
}



struct IfExpr {
    mixin ExprState;
    mixin SetGet!(Expression, "condition");
    mixin SetGet!(Scope, "ifTrue");
    mixin SetGet!(Scope, "ifFalse");
    // Scope ifTrue;
    // Scope ifFalse;

    string[] toLines() {
        // string s = "if:\n" ~
        // getTab("condition:\n" ~getTab(condition,2)) ~
        // getTab("then:\n" ~ifTrue.map!(a=>getTab(a,2)).array.join);
        // if (ifFalse.length > 0)
        // s ~= getTab("else:\n"~ifFalse.map!(a=>getTab(a,2)).array.join);
        
        return ["if"] ~
            getTab(["condition"] ~ condition.toLines.getTab) ~
            getTab(["then"] ~ ifTrue.toLines.getTab) ~
            getTab(["else"] ~ ifFalse.toLines.getTab);
    }
}

struct Declaration {
    mixin ExprState;
    string name;
    /// Due to an error in DMD, this cannot use the Nullable wrapper, pointer or otherwise.
    Expression* initial;

    Expression unwrap_initial() {
        assert(initial, "value is none.");
        return *initial;
    }
    void some_initial(Expression ex) {
        if (!initial) initial = new Expression();
        *initial = ex;
    }

    string[] toLines() {
        return ["def:"] ~
            getTab(
                ["name: " ~ name] ~ 
                (initial ? (*initial).toLines : ["none"])
            );
    }
}

struct Assignment {
    mixin ExprState;
    mixin SetGet!(Expression, "lhs");
    mixin SetGet!(Expression, "rhs");

    string[] toLines() {
        import std.algorithm : map;

        // string[] argsStr;
        // foreach (a; args) argsStr ~= a.to!string;
        return (
            ["assign:"] ~
            getTab(
                ["to:"] ~ lhs.toLines.getTab ~
                ["=:"]  ~ rhs.toLines.getTab
            )
        );
    }
}


struct BinaryOp(string op) {
    mixin ExprState;
}

struct FuncLiteral {
    mixin ExprState;
    Declaration[] args;
    Scope* scop;
    this(typeof(args) args_, typeof(*scop) scop_) {
        args = args_;
        *scop = scop_;
    }

    string[] toLines() {
        import std.algorithm : map;

        // string[] argsStr;
        // foreach (a; args) argsStr ~= a.to!string;
        return (
            ["func:"] ~
            getTab(
                ["args:"] ~
                args.getTabArray ~
                (*scop).toLines
            )
        );
    }
}


struct CallExpr {
    mixin ExprState;
    mixin SetGet!(Expression, "caller");
    Expression[] args;

    string[] toLines() {
        import std.algorithm : map;

        // string[] argsStr;
        // foreach (a; args) argsStr ~= a.to!string;
        return (
            ["call:"] ~
            getTab(
                ["caller:"] ~ caller.toLines.getTab ~
                ["args:"] ~ args.getTabArray
            )
        );
    }
}

// //*/