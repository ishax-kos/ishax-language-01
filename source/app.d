import std.stdio;
import parse;
import std.stdio;


void main() {
    // Tree state = new Tree();
    file = new File(`code/main.dn`, "rb");
    // writeln(state.file.tell());
    // auto b = state.file.eof;
    // writeln(state.file.tell());
    if (parseGlobal()) writeln("success");
    else writeln("parse failed");
}

