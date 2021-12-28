import std.stdio;
import parse;
import std.stdio;
import ast;


void main () 
{
    file = loadSource("code/test.dn");
    // assert(cast(string)parseIdentifier() == "myFoe");
    auto ast = parseGlobal;
    assert(ast);
    writefln!"%(%s\n%)"(ast);
}

