module test2;



//import core.stdc.stdio;
import std.stdio;
import std.traits;
import std.algorithm.comparison;


class A {}
class B {}
class C {}


string max(A val) {return "A...";}
string max(B val) {return "B...";}
string max(C val) {return "C...";}

pragma(msg, __MODULE__);
pragma(msg,
    typeid(__traits(getOverloads, mixin(__MODULE__), "max", true))
);