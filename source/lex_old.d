module lex_old;
import std.stdio;
import std.uni;
// import std.conv: parse;
// import std.sumtype;
// import std.typecons: Tuple;


Token KW_extern = Token(Tok.extern_, "extern");
Token KW_semi = Token(Tok.semi_, ";");
Token KW_def = Token(Tok.def_, ":");
Token KW_if = Token(Tok.if_, "if");
Token TK_EOF = Token(Tok.EOF_, "");

struct Token {
    Tok type;
    union {
        dstring str;
        string text;
        // () {return cast(string) str;}
    }
}

Token* newToken(Tok type, dstring str) {
    Token* t = new Token();
    if (type != Tok.string_) {
        t.text = cast(string) str;
    }
    else {
        t.str = str;
    }
    return t;
}
Token* newToken(dstring str) {return newToken(Tok.symbol_, str);}


enum Tok {
    EOF_,
    if_,
    // fn_,
    extern_,
    
    symbol_,

    semi_,
    def_,

    /// Terminals
    identifier_,
    number_,
    string_
}


File file;


dchar getChar() {
    char[1] b;
    file.rawRead(b);
    return cast(dchar) b[0];
}


dchar lastChar = ' ';


Token* getToken() {
    // assert(file.isOpen);
    // size_t startPos = file.tell();
    /// Skip whitespace
    while (lastChar.isWhite()) {
        lastChar = getChar();
    }

    /// identifiers
    if (lastChar.isLower()) {
        dstring identifierStr = [lastChar];

        while (1) {
            lastChar = getChar();
            if (!isAlphaNum(lastChar)) break;
            identifierStr ~= lastChar;
            // writeln("+ -- ", identifierStr);
        }

        if (identifierStr == "extern") {
            return &KW_extern;
        }
        // if (identifierStr == "fn") {
        //     return &KW_fn;
        // }
        if (identifierStr == "if") {
            return &KW_if;
        }
        
        return newToken(Tok.identifier_, identifierStr);
    }


    if (lastChar.isNumber()) {
         dstring numStr;
        while (1) {
            numStr ~= lastChar;
            lastChar = getChar();
            if (!(lastChar.isNumber())) break;
        }
        
        return newToken(Tok.number_, numStr);
    }
    
    


    /// Strings
    if (lastChar == '"') {
         dstring strStr;
        while (1) {
            lastChar = getChar();
            if (file.eof || lastChar == '"') break;
            strStr ~= lastChar;
        }
        Token* t = newToken(Tok.string_, ""d);
        t.str = strStr;
        if (!file.eof) return t;
    }

    /// Comments
    if (lastChar == '\\') {
        if ((lastChar = getChar()) == '\\') {
            while (1) {
                lastChar = getChar();
                if (file.eof || lastChar == '\n' || lastChar == '\r') break;
            }
        }
        if (!file.eof) return getToken();
    }

    if (file.eof) {
        return &TK_EOF;
    }

    // file.seek(startPos);
    dstring str = [lastChar];
    lastChar = getChar();
    return newToken(Tok.symbol_, str);

    assert(0);
}