module parse;

public import parse.node;
public import parse.terminal;
public import parse.core;
public import parse.top;


import std.stdio;


unittest {
    import ast;
    file = loadSource("code/main.dn");

    auto tree = parseGlobal();
    // assert(tree);
    writeln(tree);
    writeln(tree.statements.length);

    // writeln(file.tell);
    // parseSym!"{";
    // writeln(file.tell);
    // parseSym!".";
    // writeln(file.tell);
    // parseSym!"}";
    // writeln(file.tell);
    
}

