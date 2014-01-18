// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSfile.

part of clean_data;


class DataList extends Object with ChangeNotificationsMixin, ChangeChildNotificationsMixin, ListMixin implements List {
  List _list = new List();

  get length => _length;
  set length(newLen) {
    _length = newLen;
    _notify();
  }

  get _length => _list.length;
  set _length(int newLen) {
    if(newLen < 0) throw new RangeError('Negative position');
    while(newLen > _length) _add(new DataReference(null));
    while(newLen < _length) _remove(_list.last);
  }

  _add(DataReference value) {
    _list.add(value);
    _addOnDataChangeListener(_list.length-1, value);
    _markAdded(_list.length -1, value.value);
  }

  _set(key, DataReference value) {
    _markChanged(key, new Change(_list[key].value, value.value));
    _removeOnDataChangeListener(key);
    _list[key] = value;
    _addOnDataChangeListener(key, value);
  }


  dynamic operator [](key) => _list[key].value;
  operator []=(key, dynamic value) { _list[key].value = value; }

  DataList(){}

  factory DataList.from(Iterable elements) {
    DataList dataList =  new DataList()..addAll(elements);
    dataList._clearChanges();
    dataList._clearChangesSync();
    return dataList;
  }

  DataReference ref(int pos) => _list[pos];

  // Iterable interface.
  Iterator get iterator => _list.map((DataReference ref) => ref.value).iterator;

  void add(element, {author: null}) {
    _add(new DataReference(element));
    _notify(author: author);
  }

  void addAll(Iterable iterable, {author: null}) {
    for (dynamic element in iterable) {
      _add(new DataReference(element));
    }
    _notify(author: author);
  }

  bool remove(Object element, {author: null}) {
    int index = indexOf(element);
    if(index == -1) return false;
    var ret = _remove(ref(index));
    _notify(author: author);
    return ret;
  }

  bool _remove(DataReference element) {
    for (int i = 0; i < this.length; i++) {
      if (ref(i) == element) {
        _removeOnDataChangeListener(i);
        this._setRange(i, this.length - 1, _list, i + 1);
        _markRemoved(length-1, ref(length-1).value);
        _list.length -= 1;
        return true;
      }
    }
    return false;
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
      var element = source.ref(i);
      if (test(element.value) != retainMatching) {
         source._remove(element);
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

  void _rangeCheck(int start, int end) {
    if (start < 0 || start > this.length) {
      throw new RangeError.range(start, 0, this.length);
    }
    if (end < start || end > this.length) {
      throw new RangeError.range(end, start, this.length);
    }
  }

  void _markAllRemoved(){
    for(int i=0; i < _list.length; i++) {
      _markChanged(i, new Change(_list[i].value, undefined));
    }
  }

  void _markAllAdded(){
    for(int i=0; i < _list.length; i++) {
      _markChanged(i, new Change(undefined, _list[i].value));
    }
  }


  void sort([int compare(a, b)]) {
    if (compare == null) {
      var defaultCompare = Comparable.compare;
      compare = defaultCompare;
    }
    _markAllRemoved();
    _list.sort((a,b) => compare(a.value, b.value));
    _markAllAdded();
    _notify();
  }

  void shuffle([Random random]) {
    _markAllRemoved();
    _list.shuffle(random);
    _markAllAdded();
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
    for(int i = end-1; i >= start; i--) _remove(ref(i));
    _notify(author: author);
  }

  void fillRange(int start, int end, [fill, author]) {
    _rangeCheck(start, end);
    for (int i = start; i < end; i++) {
      _set(i, new DataReference(fill));
    }
    _notify(author: author);
  }

  void setRange(int start, int end, Iterable iterable, [int skipCount = 0, author]) {
    _rangeCheck(start, end);
    for(var elem in iterable) {
      if(start < end) _list[start].value = elem;
      start++;
    }
    _notify(author: author);
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

  void replaceRange(int start, int end, Iterable newContents, {author: null}) {
    _rangeCheck(start, end);
    newContents = newContents.toList().map((E) => new DataReference(E));
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
      _add(new DataReference(element));
      return;
    }
    // We are modifying the length just below the is-check. Without the check
    // Array.copy could throw an exception, leaving the list in a bad state
    // (with a length that has been increased, but without a new element).
    if (index is! int) throw new ArgumentError(index);
    this._length++;
    _setRange(index + 1, this.length, _list, index);
    _set(index, new DataReference(element));
    _notify(author: author);
  }

  removeAt(int index, {author: null}) {
    var result = this[index];
    _remove(ref(index));
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
      _set(index++, new DataReference(element));
    }
    _notify(author: author);
  }

  void setAll(int index, Iterable iterable, {author: null}) {
    for (dynamic element in iterable) {
      _list[index++].value = element;
    }
    _notify(author: author);
  }

  void dispose() {
    _dispose();
  }

}
