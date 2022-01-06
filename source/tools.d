module tools;
import std.sumtype;
import std.conv : to;
public import std.sumtype;
import std.traits;
public import std.typecons : Option = Nullable, some = nullable;


private T pass(T)(T val) {return val;}

bool isAn(T, U)(U val) {
	return typeid(val) == typeid(T);
}

bool isSome(T)(T res) {
    return !res.isNull;
}

/+~~Unit type~~+/
alias Unit = size_t[0];
enum nil = Unit.init;



/+~~Optional type~~+//*
struct None {}
alias Option(T...) = SumType!(None, T);


auto get(T, TT)(TT res) {
    import std.traits;
    // alias RetT = TemplateArgsOf!T;
    return res.match!(
        nullOut!T,
        (v)=>v
    )();
}


bool isNone(T)(T res) {
    return res.match!(
        (None e) => true,
        (_) => false
    )();
}



private T nullOut(T)(None e) {assert(0, "Tried to unwrap on empty!");}

*/

/+~~Result type~~+/
