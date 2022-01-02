import std.stdio;
import parse;
import std.stdio;
import ast;


void main () {
    file = loadSource("code/main.dn");
    // assert(cast(string)parseIdentifier() == "myFoe");
    auto ast = parseGlobal;
    assert(ast);
    writefln!"%(%s\n%)"(ast);
}

// import std.stdio;

// import llvm;


// void main(string[] args) {
//     writefln("found LLVM verison %s.", [LLVM_VERSION_MAJOR, LLVM_VERSION_MINOR, LLVM_VERSION_PATCH]);
// 	static if((asVersion(3, 3, 0) <= LLVM_Version) 
//      && (LLVM_Version < asVersion(3, 5, 0))) {
// 		writefln("LLVM multithreading on? %s", cast(bool) LLVMIsMultithreaded());
// 		writefln("Turning it on"); LLVMStartMultithreaded();
// 		writefln("LLVM multithreading on? %s", cast(bool) LLVMIsMultithreaded());
// 		writefln("Turning it off"); LLVMStopMultithreaded();
// 		writefln("LLVM multithreading on? %s", cast(bool) LLVMIsMultithreaded());
// 	}
    
// }