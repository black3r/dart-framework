// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSfile.

part of clean_data;

refcl(data){
  return cleanify(data);
}

abstract class DataListView extends Object with ChangeNotificationsMixin, ChangeChildNotificationsMixin, IterableMixin implements Iterable {
  List _list = new List();
  get length => _length;
  get _length => _list.length;
  dynamic operator [](key) => _list[key] is DataReference ? _list[key].value : _list[key];
  DataReference ref(int pos) {
    if(_list[pos] is! DataReference) {
      _removeOnDataChangeListener(pos);
      _list[pos] = new DataReference(_list[pos]);
      _addOnDataChangeListener(pos, _list[pos]);
    }
    return _list[pos];
  }

  _silentAdd(dynamic value){
    _list.add(value);
    if(value is ChangeNotificationsMixin) _addOnDataChangeListener(_list.length-1, value);
  }

  _add(dynamic value) {
    _list.add(value);
    if(value is ChangeNotificationsMixin) _addOnDataChangeListener(_list.length-1, value);
    _markAdded(_list.length - 1, this[_list.length - 1]);
  }

  _set(key, dynamic value) {
    Change change = new Change();
    if(value is DataReference) _markChanged(key, new Change(this[key], value.value));
    else _markChanged(key, new Change(this[key], value));
    _removeOnDataChangeListener(key);
    _list[key] = value;
    if(value is ChangeNotificationsMixin) _addOnDataChangeListener(key, value);
  }

  bool _remove(int index) {
    if(index < 0 || index >= _list.length) return false;
    _removeOnDataChangeListener(_list.length - 1);
    this._setRange(index, this.length - 1, _list, index + 1);
    _markRemoved(length-1, this[length - 1]);
    _list.length -= 1;
    return true;
  }

  DataListView(){}

  // Iterable interface.
  Iterator get iterator => _list.map((elem) => elem is DataReference ? elem.value : elem).iterator;

  void _rangeCheck(int start, int end) {
    if (start < 0 || start > this.length) {
      throw new RangeError.range(start, 0, this.length);
    }
    if (end < start || end > this.length) {
      throw new RangeError.range(end, start, this.length);
    }
  }

  void _changeAllBefore(){
    for(int i=0; i < _list.length; i++) {
      _markChanged(i, new Change(this[i], undefined));
      _removeOnDataChangeListener(i);
    }
  }

  void _changeAllAfter(){
    for(int i=0; i < _list.length; i++) {
      _markChanged(i, new Change(undefined, this[i]));
      if(_list[i] is ChangeNotificationsMixin)
        _addOnDataChangeListener(i, _list[i]);
    }
  }

  void dispose() {
    _dispose();
  }

  String toString() => _list.toString();

  void _sort([int compare(a, b)]) {
    if (compare == null) {
      compare = Comparable.compare;
    }
    _changeAllBefore();
    _list.sort((a,b) => compare(a is DataReference ? a.value : a, b is DataReference ? b.value : b));
    _changeAllAfter();
  }

  void _setRange(int start, int end, Iterable<DataReference> iterable, [int skipCount = 0]) {
    _rangeCheck(start, end);
    int length = end - start;
    if (length == 0) return;

    if (skipCount < 0) throw new ArgumentError(skipCount);

    List otherList;
    int otherStart;
    // TODO(floitsch): Make this accept more.
    if (iterable is List) {
      otherList = iterable;
      otherStart = skipCount;
    } else {
      otherList = iterable.skip(skipCount).toList(growable: false);
      otherStart = 0;
    }
    if (otherStart + length > otherList.length) {
      throw new StateError("Not enough elements");
    }
    if (otherStart < start) {
      // Copy backwards to ensure correct copy if [from] is this.
      for (int i = length - 1; i >= 0; i--) {
        _set(start + i, otherList[otherStart + i]);
      }
    } else {
      for (int i = 0; i < length; i++) {
        _set(start + i, otherList[otherStart + i]);
      }
    }
  }
}

class DataList extends DataListView with ListMixin implements List {
  set length(newLen) {
    _length = newLen;
    _notify();
  }

  set _length(int newLen) {
    if(newLen < 0) throw new RangeError('Negative position');
    while(newLen > _length) _add(null);
    while(newLen < _length) _remove(_list.length - 1);
  }

  operator []=(key, dynamic value) => _set(key, refcl(value));

  DataList(){}

  factory DataList.from(Iterable elements) {
    DataList dataList =  new DataList();
    elements.forEach((elem) => dataList._silentAdd(refcl(elem)));
    return dataList;
  }

  void add(element, {author: null}) {
    _add(refcl(element));
    _notify(author: author);
  }

  set(int key, dynamic value, {author: null}) {
    _set(key, refcl(value));
    _notify(author: author);
  }

  void addAll(Iterable iterable, {author: null}) {
    for (dynamic element in iterable) {
      _add(refcl(element));
    }
    _notify(author: author);
  }

  bool remove(Object element, {author: null}) {
    int index = indexOf(element);
    if(index == -1) return false;
    var ret = _remove(index);
    _notify(author: author);
    return ret;
  }

  void removeWhere(bool test(element), {author: null}) {
    _filter(this, test, false);
    _notify(author: author);
  }

  void retainWhere(bool test(element), {author: null}) {
    _filter(this, test, true);
    _notify(author: author);
  }

  // TODO: filter should run in linear time
  static void _filter(DataList source,
                      bool test(var element),
                      bool retainMatching) {
    int length = source.length;
    for (int i = length - 1; i >= 0; i--) {
      if (test(source[i]) != retainMatching) {
         source._remove(i);
      }
    }
  }

  void clear({author: null}) { this._length = 0; _notify(author: author); }

  // List interface.

  removeLast({author: null}) {
    if (length == 0) {
      throw new StateError("No elements");
    }
    var result = this[length - 1];
    _length--;
    _notify(author: author);
    return result;
  }

  void sort([int compare(a, b)]) {
    _sort(compare);
    _notify();
  }

  void shuffle([Random random]) {
    _changeAllBefore();
    _list.shuffle(random);
    _changeAllAfter();
    _notify();
  }

  DataList sublist(int start, [int end]) {
    if (end == null) end = this.length;
    _rangeCheck(start, end);
    int length = end - start;
    List result = new DataList()..length = length;
    for (int i = 0; i < length; i++) {
      result[i] = this[start + i];
    }
    return result;
  }

  void removeRange(int start, int end, {author: null}) {
    _rangeCheck(start, end);
    int length = end - start;
    for(int i = end-1; i >= start; i--) _remove(i);
    _notify(author: author);
  }

  void fillRange(int start, int end, [fill, author]) {
    _rangeCheck(start, end);
    for (int i = start; i < end; i++) {
      _set(i, refcl(fill));
    }
    _notify(author: author);
  }

  void setRange(int start, int end, Iterable iterable, [int skipCount = 0, author]) {
    _rangeCheck(start, end);
    for(var elem in iterable) {
      if(start < end) this[start] = refcl(elem);
      start++;
    }
    _notify(author: author);
  }



  void replaceRange(int start, int end, Iterable newContents, {author: null}) {
    _rangeCheck(start, end);
    newContents = newContents.toList().map((E) => refcl(E));
    int removeLength = end - start;
    int insertLength = newContents.length;
    if (removeLength >= insertLength) {
      int delta = removeLength - insertLength;
      int insertEnd = start + insertLength;
      int newLength = this.length - delta;
      this._setRange(start, insertEnd, newContents);
      if (delta != 0) {
        this._setRange(insertEnd, newLength, _list, end);
        this._length = newLength;
      }
    } else {
      int delta = insertLength - removeLength;
      int newLength = this.length + delta;
      int insertEnd = start + insertLength;  // aka. end + delta.
      this._length = newLength;
      this._setRange(insertEnd, newLength, _list, end);
      this._setRange(start, insertEnd, newContents);
    }
    _notify(author: author);
  }


  void insert(int index, element, {author: null}) {
    if (index < 0 || index > length) {
      throw new RangeError.range(index, 0, length);
    }
    if (index == this.length) {
      _add(refcl(element));
      return;
    }
    // We are modifying the length just below the is-check. Without the check
    // Array.copy could throw an exception, leaving the list in a bad state
    // (with a length that has been increased, but without a new element).
    if (index is! int) throw new ArgumentError(index);
    this._length++;
    _setRange(index + 1, this.length, _list, index);
    _set(index, refcl(element));
    _notify(author: author);
  }

  removeAt(int index, {author: null}) {
    var result = this[index];
    _remove(index);
    _notify(author: author);
    return result;
  }

  void insertAll(int index, Iterable iterable, {author: null}) {
    if (index < 0 || index > length) {
      throw new RangeError.range(index, 0, length);
    }
    iterable = iterable.toList();
    int insertionLength = iterable.length;
    // There might be errors after the length change, in which case the list
    // will end up being modified but the operation not complete. Unless we
    // always go through a "toList" we can't really avoid that.
    this._length += insertionLength;
    _setRange(index + insertionLength, this.length, _list, index);
    for (dynamic element in iterable) {
      _set(index++, refcl(element));
    }
    _notify(author: author);
  }

  void setAll(int index, Iterable iterable, {author: null}) {
    for (dynamic element in iterable) {
      this[index++]= refcl(element);
    }
    _notify(author: author);
  }

}
