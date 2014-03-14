library inbuilts;

import "dart:io";
import "dart:collection";
import "dart:math";
import "sprintf.dart";

class $PyFile {
    var handle;
    var closed, mode, name, softspace;

    $PyFile(name, mode) {
        closed = false;
        this.name = name;
        this.mode = mode;
        softspace = true;

        switch (mode) {
        case "r":
            handle = new File(name).openSync(mode: FileMode.READ);
            break;

        case "w":
            handle = new File(name).openSync(mode: FileMode.WRITE);
            break;
        }
    }

    read([bytes]) {
        if (bytes == null)
            bytes = handle.lengthSync();

        return new $PyString(new String.fromCharCodes(handle.readSync(bytes)));
    }

    readlines() {
        return new $PyString(new File(name).readAsLinesSync());
    }

    write(data) {
        handle.writeStringSync(data);
    }

    writelines(lines) {
        for (int i = 0; i < lines.length; i++)
            handle.writeStringSync(lines[i] + "\n");
    }

    tell() {
        return handle.positionSync();
    }

    seek(position, [whence]) {
        if (whence == null)
            whence = 0;

        switch(whence) {
        case 0:
            handle.setPositionSync(position);
            break;

        case 1:
            handle.setPositionSync(handle.positionSync() + position);
            break;

        case 2:
            handle.setPositionSync(handle.lengthSync() + position);
            break;
        }
    }

    close() {
        closed = true;
        handle.closeSync();
    }
}

$PyFile open(name, [mode]) {
    name = name.toString();

    if (mode == null)
        mode = "r";
    else
        mode = mode.toString();

    var file = new $PyFile(name, mode);

    if ((mode == "r" || mode == "rb") && !new File(name).existsSync())
        throw new FileSystemException();

    return file;
}

class $PyTuple extends IterableBase {
    var tuple = [];

    $PyTuple(iterable) {
        if (iterable is $PyTuple)
            this.tuple = iterable.tuple;
        else {
            for (var item in iterable)
                tuple.add(item);
        }
    }

    toString() {
        var i = 0, str = "(";

        for (i = 0; i < tuple.length; i++) {
            str += tuple[i].toString();
            if (i < tuple.length - 1 || tuple.length == 1)
                str += ", ";
        }
        str += ")";

        return str;
    }

    operator [](i) => tuple[i];

    operator []=(i, j) {
        throw "Assignment not possible in Tuple";
    }

    operator +(tupleObj) {
        if (tupleObj is $PyTuple) {
            var newTupObj = new $PyTuple(this.tuple);

            for (var item in tupleObj.tuple)
                newTupObj.tuple.add(item);

            return newTupObj;
        }
        else
            throw "Invalid operand for concatenation";
    }

    operator *(integer) {
        if (integer is int) {
            var newTupObj = new $PyTuple([]);

            for (var i = 0; i < integer; i++) {
                for (var item in this.tuple)
                    newTupObj.tuple.add(item);
            }

            return newTupObj;
        }
        else
            throw "Invalid Multiplier";
    }

    getList() => tuple;
    contains(comparator) => tuple.contains(comparator);
    get iterator => tuple.iterator;
}

tuple(iterable) => new $PyTuple(iterable);

class $PyString extends IterableBase {
    var _str;

    $PyString(string) {
        _str = string;
    }

    get iterator => this.toList().iterator;

    capitalize() {
        var capzed = _str.toLowerCase();

        if (capzed.length > 0)
            return new $PyString(capzed.replaceFirst(capzed[0], capzed[0].toUpperCase()));
        else
            return new $PyString(capzed);
    }

    zfill(width) {
        if (!(width is num))
            throw "TypeError: an integer is required";

        var toPad = width - _str.length, pad = "";

        for (var i = 0; i < toPad; i++)
            pad += "0";

        return new $PyString(pad + _str);
    }

    toString() => _str;
    get hashCode => _str.hashCode;

    toList() {
        var list = [];
        for (var i in _str.split('')){
            list.add(new $PyString(i));
        }
        return list;
    }

    operator ==(str) => _str == str.toString();
    operator +(str) => new $PyString(_str + str.toString());

    operator %(collection) {
        var string = this.toString();

        if (collection is $PyTuple) {
            RegExp exp = new RegExp(r"%\s?[diuoxXeEfFgGcrs]");
            Iterable<Match> matches = exp.allMatches(string);
            var i = 0;
            var List = collection.getList();
            for(var m in matches) {
                String match = m.group(0);
                if (match == "%s" || match == "% s")
                    List[i] = List[i].toString();
                if ((match == "%d" || match == "% d") && List[i] is bool){
                    if (List[i])
                        List[i] = 1;
                    else
                        List[i] = 0;
                }
                i++;
            }
            return new $PyString($sprintf(string, List));
        } else if(collection is $PyDict) {
            RegExp exp = new RegExp(r"%(\([a-zA-Z_]+\))*\s?[diuoxXeEfFgGcrs]");
            var List = [];
            Iterable<Match> matches = exp.allMatches(string);
            var i = 0;
            var currentIndex = 0;
            var newString = "";
            var key = "";
            for(var m in matches){
                String match = m.group(0);
                while(currentIndex <= m.start)
                    newString += string[currentIndex++];

                currentIndex = m.start + 2;
                while(string[currentIndex] != ")")
                    key += string[currentIndex++];

                currentIndex = m.end - 1;
                if(string[currentIndex] == "s")
                    List.add(collection[key].toString());
                else if(string[currentIndex] == "d" && collection[key] is bool){
                    if(collection[key])
                        List.add(1);
                    else
                        List.add(0);
                }
                else
                    List.add(collection[key]);
                key = "";
                newString += string[currentIndex++];
            }
            return new $PyString($sprintf(newString, List));
        }
    }

    format(list, dictionary) {
        var string = this.toString();
        RegExp exp = new RegExp(r"{\d+}|{[a-zA-Z0-9_]+}");
        Iterable<Match> matches = exp.allMatches(string);
        var i = 0;
        var currentIndex = 0;
        var newString = "";
        var key;

        for (var m in matches) {
            String match = m.group(0);
            key = "";
            while(currentIndex < m.start)
                newString += string[currentIndex++];

            currentIndex++;
            while(string[currentIndex] != "}")
                key += string[currentIndex++];

            exp = new RegExp(r"{\d+}");
            if(exp.hasMatch(match))
                newString += list[int.parse(key)].toString();
            else
                newString += dictionary[key].toString();

            currentIndex = m.end;
        }
        return new $PyString(newString);
    }

    operator *(mul) {
        if (mul is! int)
            throw "Invalid multplier for String";

        var pdt = "";
        for (var i = 0; i < mul; i++)
            pdt += _str;

        return new $PyString(pdt);
    }

    operator [](index) {
        if (index is! int)
            throw "Invalid index for String";

        return new $PyString(_str[index]);
    }
}

class $PyList extends IterableBase {
    var _list = [];

    get iterator => _list.iterator;

    $PyList([iterable]) {
        switch ($getType(iterable)) {
            case 1:
            case 2:
                _list = iterable.toList();
                break;
            case 4:
                _list = iterable.keys;
                break;
            case 5:
                _list = iterable.tuple;
                break;
            case 6:
                _list = iterable;
                break;
            case -1:
                break;
            default:
                throw "Invalid parameter";
                break;
        }
    }

    extend(list) {
        for (var item in list)
            _list.add(item);
    }

    pop([pos]) {
        var v;

        if (pos == null) {
            v = _list.last;
            _list.removeLast();
        } else {
            v = _list[pos];
            _list.removeAt(pos);
        }

        return v;
    }

    count(item) {;
        var c = 0;
        for (var elem in _list) {
            if (elem == item)
                c++;
        }
        return c;
    }

    toList() => _list;
    append(item) => _list.add(item);
    insert(pos, item) => _list.insert(pos, item);
    remove(item) => _list.remove(item);
    index(item) => _list.indexOf(item);
    sort() => _list.sort();
    reverse() => _list = _list.reversed.toList();
    toString() => _list.toString();

    operator +(iterable) {
        extend(iterable);
        return this;
    }

    operator [](index) => _list[index];
    operator []=(pos, item) => _list[pos] = item;

    operator *(mul) {
        if (mul is! int)
            throw "Invalid multplier for List";

        var pdt = new $PyList();
        for (var i = 0; i < mul; i++)
            pdt += this;

        return pdt;
    }
}

list([iterable]) => new $PyList(iterable);

class $PySet extends IterableBase {
    var _set;
    $PySet([iterable]) {
        if(iterable != null)
            this._set = new Set.from(iterable);
        else
            this._set = new Set();
    }

    get iterator => this._set.iterator;

    add(var elem) => this._set.add(elem);

    isdisjoint(var iterable) {
        var other = new $PySet(iterable);
        if(this._set.intersection(other._set).length == 0)
            return true;
        else
            return false;
    }

    issubset(var iterable) {
        var other = new $PySet(iterable);
        return other._set.containsAll(this._set);
    }

    issuperset(var iterable){
        var other = new $PySet(iterable);
        return this._set.containsAll(other._set);
    }

    union(var iterable) {
        var other = new $PySet(iterable);
        return new $PySet(this._set.union(other._set));
    }

    intersection(var iterable) {
        var other = new $PySet(iterable);
        return new $PySet(this._set.intersection(other._set));
    }

    difference(var iterable){
        var other = new $PySet(iterable);
        return new $PySet(this._set.difference(other._set));
    }

    symmetric_difference(var iterable){
        var other = new $PySet(iterable);
        return new $PySet(this._set.union(other._set).difference(this._set.intersection(other._set)));
    }

    update(var iterable){
        var other = new $PySet(iterable);
        this._set = this._set.union(other._set);
    }

    intersection_update(var iterable){
        var other = new $PySet(iterable);
        this._set = this._set.intersection(other._set);
    }

    difference_update(var iterable){
        var other = new $PySet(iterable);
        this._set = this._set.difference(other._set);
    }

    symmetric_difference_update(var iterable){
        var other = new $PySet(iterable);
        this._set = this._set.union(other._set).difference(this._set.intersection(other._set));
    }

    remove(var element) => this._set.remove(element);

    discard(var element){
        if(this._set.contains(element))
            this._set.remove(element);
    }

    toString(){
        var str = "set([" + this._set.join(",") + "])";
        return str;
    }

    clear() => this._set.clear();

    operator -(var other) {
        if(other is $PySet)
            return new $PySet(this._set.difference(other._set));
        else
            throw "Invalid Arguments";
    }

    operator ==(var other){
        if(other is $PySet){
            if(other._set.length == this._set.length){
                return this._set.difference(other._set).length == 0;
            }
            return false;
        }
        else
            throw "Invalid Arguments";
    }

    operator <=(var other){
        if(other is $PySet)
            return other._set.containsAll(this._set);
        else
            throw "Invalid Arguments";
    }

    operator <(var other){
        if(other is $PySet)
            return (this <= other && this != other);
        else
            throw "Invalid Arguments";
    }

    operator >=(var other){
        if(other is $PySet)
            return this._set.containsAll(other._set);
        else
            throw "Invalid Arguments";
    }

    operator >(var other){
        if(other is $PySet)
            return (other <= this && other != this);
        else
            throw "Invalid Arguments";
    }

    operator |(var other){
        if(other is $PySet)
            return new $PySet(this._set.union(other._set));
        else
            throw "Invalid Arguments";
    }

    operator &(var other){
        if(other is $PySet)
            return new $PySet(this._set.intersection(other._set));
        else
            throw "Invalid Arguments";
    }

    operator ^(var other){
        if(other is $PySet)
            return new $PySet(this._set.union(other._set).difference(this._set.intersection(other._set)));
        else
            throw "Invlaid Arguments";
    }

}

set([iterable]){
    return new $PySet(iterable);
}

class $PyDict extends IterableBase {
    var _dict;

    $PyDict([pairs]) {
        _dict = new Map();

        switch ($getType(pairs)) {
            case 2:
                for (var pair in pairs)
                    _dict[pair[0]] = pair[1];
                break;
            case -1:
                break;
            default:
                throw "Invalid Parameter";
                break;
        }
    }

    fromKeys(seq, [values]) {
        _dict.clear();

        for (var value in seq)
            _dict[value] = null;

        if (values != null) {
            for (var value in values)
                _dict[value] = value;
        }
    }

    get(key, [fallback]) {
        if (_dict.containsKey(key))
            return _dict[key];
        else
            return fallback;
    }

    items() {
        var items = new $PyList();
        for (var key in this)
            items.append(tuple([key, _dict[key]]));

        return items;
    }

    pop(key, [fallback]) {
        if (_dict.containsKey(key)) {
            var value = _dict[key];
            _dict.remove(key);
            return value;
        } else
            return fallback;
    }

    popitem() {
        if (_dict.length == 0)
            return;

        var rng = new Random();
        var key = _dict.keys[rng.nextInt(_dict.length)];
        var value = tuple([keys, _dict[key]]);

        _dict.remove(key);
        return value;
    }

    setdefault(key, [value]) {
        if (_dict.containsKey(key))
            return _dict[key];
        else {
            _dict[key] = value;
            return value;
        }
    }

    update([other]) {
        for (var pair in other)
            _dict[pair[0]] = pair[1];
    }

    iteritems() => items();
    iterkeys() => new $PyList(_dict.keys);
    itervalues() => new $PyList(_dict.values);
    keys() => new $PyList(_dict.keys);
    values() => new $PyList(_dict.values);
    has_key(key) => _dict.hasKey(key);
    contains(key) => has_Key(key);
    copy() => this;
    clear() => _dict.clear();
    get iterator => _dict.keys.iterator;
    toString() => _dict.toString();
    viewitems() => _dict.items();
    viewkeys() => _dict.keys;
    viewvalues() => _dict.values;
    operator [](index) => _dict[index];
    operator []=(pos, item) => _dict[pos] = item;
}

dict([pairs]) => new $PyDict(pairs);

$getType(variable) {
    if (variable is num)
        return 0;
    else if (variable is $PyString)
        return 1;
    else if (variable is $PyList)
        return 2;
    else if (variable is bool)
        return 3;
    else if (variable is $PyDict)
        return 4;
    else if (variable is $PyTuple)
        return 5;
    else if (variable is List)
        return 6;
    else
        return -1;
}

abs(n) {
    if (n is num) {
        if (n < 0)
            return (n * -1);
        else
            return n;
    }
    else
        return "Type is not a Number";
}

all(iterable) {
    var i;
    for(i in iterable){
        if(!$checkValue(i))
            return false;
    }
    return true;
}

any(iterable) {
    for (var i in iterable){
        if ($checkValue(i))
            return true;
    }
    return false;
}

bin(integer) {
    if (integer is int){
        var num1 = 0;
        var x = 0;
        while (integer > 0) {
            x = integer % 2;
            num1 = num1 * 10 + x;
            integer ~/= 2;
        }
        return num1;
    }
    else
        return "Type is not Int";
}

len(target) => target.length;
str(data) => new $PyString(data.toString());

raw_input([message]) {
    if (message != null)
        stdout.write(message);

    return new $PyString(stdin.readLineSync(encoding: SYSTEM_ENCODING));
}

input([message]) {
    if (message != null)
        stdout.write(message);

    num value;

    try {
        value = num.parse(stdin.readLineSync(encoding: SYSTEM_ENCODING));
        return value;
    } catch (ex) {
        print("Fatal Error: Non numeric characters in input; Try raw_input()");
        exit(1);
    }
}

sum(var iterable,[start = 0]){
    if(start is $PyString){
        print("TypeError: sum() can't sum strings [use ''.join(seq) instead]");
        exit(1);
    }
    var total = start;
    for(var i in iterable)
        total += i;
    return total;
}

$checkValue(value){
    var i = value;
    switch($getType(i)){
        case -1:
            if(i != null)
                return true;
            break;
        case 0:
            if(i != 0)
                return true;
            break;
        case 1:
            if(i != "")
                return true;
            break;
        case 2:
            if(i.length != 0)
                return true;
            break;
        case 3:
            if(i == true)
                return true;
            break;
        case 4:
            var keys = i.keys;
            if(keys.length != 0)
                return true;
            break;
    }
    return false;
}

$and(list){
    var condition;
    for(var i = 0; i < list.length; i++){
        if(!$checkValue(list[i])){
            if(list[i] == null)
                return "None";
            return list[i];
        }
    }
    return list[list.length - 1];
}

$or(list){
    var condition;
    for(var i = 0; i < list.length; i++){
        if($checkValue(list[i]))
            return list[i];
    }
    if(list[list.length - 1] == null)
        return "None";
    return list[list.length - 1];
}

$generator(var function){
    var list = function();
    return list;
}

class $Range extends Object with IterableMixin<int> {
    $Range(int this.start, [int this.stop, int this.step = 1]) {
        if (stop == null ) {
            stop = start;
            start = 0;
        }

        if (step == 0)
            throw new ArgumentError("step must not be 0");
    }

    Iterator<int> get iterator {
        return new $RangeIterator(start, stop, step);
    }

    int get length {
        if ((step > 0 && start > stop) || (step < 0 && start < stop))
            return 0;
        return ((stop - start) / step).ceil();
    }

    bool get isEmpty => length == 0;

    int get hashCode {
        int result = 17;
        result = 37 * result + start.hashCode;
        result = 37 * result + stop.hashCode;
        result = 37 * result + step.hashCode;
        return result;
    }

    String toString() => step == 1 ? "Range($start, $stop)" : "Range($start, $stop, $step)";

    bool every(bool f(int e)) {
        for (int e in this) {
            if (f(e) == false)
                return false;
        }
        return true;
    }

    bool some(bool f(int e)) {
        for (int e in this) {
            if (f(e))
                return true;
        }
        return false;
    }

    void forEach(void f(int e)) {
        for (int e in this)
            f(e);
    }

    List<int> filter(bool f(int e)) {
        var l = new List<int>();
        for (int e in this) {
            if (f(e))
                l.add(e);
        }
        return l;
    }

    bool operator == (Range other) {
        return (other != null && start == other.start && stop == other.stop && step == other.step);
    }

    int start;
    int stop;
    final int step;
}

class $RangeIterator implements Iterator<int> {
    int _pos;
    final int _stop;
    final int _step;

    $RangeIterator(int pos, int stop, int step) : _stop = stop, _pos = pos-step, _step = step;

    get current => _pos;

    bool moveNext() {
        if (_step > 0  ? _pos + _step> _stop - 1 : _pos + _step < _stop + 1)
            return false;

        _pos += _step;
        return true;
    }
}

range(int start_inclusive, [int stop_exclusive, int step = 1]) => new $Range(start_inclusive, stop_exclusive, step);
xrange(int start_inclusive, [int stop_exclusive, int step = 1]) => new $Range(start_inclusive, stop_exclusive, step);
indices(lengthable) => new $Range(0, lengthable.length);