module main;

import std.stdio;
import std.stdio;

import parse;
import ast;


void main() {
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
