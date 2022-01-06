module parse;

import parse.node;
import parse.terminal;
import parse.core;
import parse.top;

import std.stdio;


unittest {
    file = loadSource("code/main.dn");
    // assert(cast(string)parseIdentifier() == "myFoe");
    auto ast = parseGlobal();
    assert(ast);
    writefln!"%(%s\n%)"(ast);
    // writefln!"%s"(ast);W
}
