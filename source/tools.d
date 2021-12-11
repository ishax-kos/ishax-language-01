module tools;

// public import;


bool isAn(T, U)(U val) {
	return typeid(val) == typeid(T);
}


alias Unit = size_t[0];
enum unit = Unit.init;


class Ref(T) {
    T inside;
    alias inside this;

    this(T val) {
        inside = val;
    }
}



