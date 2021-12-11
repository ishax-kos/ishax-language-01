module symbols;

import std.container.slist;
// struct Symbol {
//     string name;
// }
// alias Symbol = string;


struct Symbol {
    string name;
}


void require(ref Symbol sym, string name) {
    sym.name = name;
}


struct TypeSig {

}
alias SymbolTable = TypeSig[Symbol];
SList!(SymbolTable) nameSpaceStack;

