module symbols;

import std.container.slist;
// struct Symbol {
//     string name;
// }
alias Symbol = string;

struct TypeSig {

}
alias SymbolTable = TypeSig[Symbol];
SList!(SymbolTable) nameSpaceStack;

