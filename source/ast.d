module ast;
import tools;
import option;




class Declaration : Statement {
    string name;
    Option!bool type;
    Expression init;
}

class Assignment : Statement {}

class Expression {
    this() {}
}

interface Statement {}

// class NodeEOF : NodeAST {}