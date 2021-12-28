module ast;
import tools;
//import option;
import symbols;

import std.format: format;
import std.range: repeat;
import std.conv: to;
import std.array: array, join;

alias Type = bool;

string[] getTab(string[] strList...) {
	import std.algorithm;
	import std.range;
	return strList.map!(a=>("  "~a))().array;
}
string[] getTab(T)(T[] strList) {
	import std.algorithm;
	import std.range;
	return strList.map!(to!string).array.getTab;
}

class Expression : Statement {
    Type returnType;
    
    string[] toLines() {
    	return [typeid(this).to!string];
    }
    
    override 
    string toString () {
    	return this.toLines.join('\n');
    }
}


class Declaration : Expression {
    string name;
    Type type;
    Expression initial;
    this(string str) {name = str;}

    override 
    string[] toLines () {
        return 
            "def:\n" ~
            getTab(
            	["name: %s".format(name)]~
	            getTab(initial.to!string)
            );
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

    //override
    //string toString() {
        //import std.algorithm: map;
        //string[] argsStr;
        //foreach (a; args) argsStr ~= a.to!string;
        //return 
        	//"func:\n" ~
        	//getTab(
	        	//getTab(
	        		//"args:",
	            	//getTab(args)
	          	//),
	        	//getTab(
	        		//"scope:",
	            	//getTab(scop)
	            //)
	        //);
    //}
}
class VarExpr : Expression, Terminal {
    Symbol name;
}
class StringLit : Expression, Terminal {}
class NumLit : Expression, Terminal {}

class IfExpr : Expression {
	Expression condition;
	Statement[] ifTrue;
	Statement[] ifFalse;
	
    //override
    //string toString() {
        //import std.algorithm: map;
        //string s = "if:\n" ~
            //getTab("condition:\n" ~getTab(condition,2)) ~
            //getTab("then:\n" ~ifTrue.map!(a=>getTab(a,2)).array.join);
        //if (ifFalse.length > 0)
            //s ~= getTab("else:\n"~ifFalse.map!(a=>getTab(a,2)).array.join);
        //return s;
    //}
}


class CallExpr : Expression {
	Symbol name;
}


struct NodeSep(T) {
    string name;
    T data;
    string toString() {
        return
            name ~ "\n" ~
            getTab(data);
    }
}
