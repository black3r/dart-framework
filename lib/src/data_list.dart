// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSfile.

part of clean_data;

Set _toStringVisiting = new HashSet.identity();

//TODO returning references
class DataList extends Object with ChangeNotificationsMixin, ChangeChildNotificationsMixin implements List {
  List list = new List();

  get length => _length;
  set length(newLen) {
    _length = newLen;
    _notify();
  }

  get _length => list.length;
  set _length(int newLen) {
    if(newLen < 0) throw new RangeError('Negative position');
    while(newLen > _length) _add(null);
    while(newLen < _length) _remove(list.last);
  }

  _add(dynamic value) {
    DataReference ref = new DataReference(value);
    list.add(ref);
    _addOnDataChangeListener(list.length-1, ref);
    _markAdded(list.length -1, ref);
  }


  _set(key, DataReference value) {
    _markChanged(key, new Change(list[key], value));
    _removeOnDataChangeListener(key);
    list[key] = value;
    _addOnDataChangeListener(key, value);
  }

  DataReference _get(key) => list[key];

  dynamic operator [](key) => list[key].value;
  operator []=(key, dynamic value) { list[key].value = value; }

  DataList(){}

  factory DataList.from(Iterable elements) {
    DataList dataList =  new DataList()..addAll(elements);
    dataList._clearChanges();
    return dataList;
  }

  DataReference ref(int pos) {
    return list[pos];
  }

  // Iterable interface.
  Iterator get iterator => list.map((DataReference ref) => ref.value).iterator;

  dynamic elementAt(int index) => this[index];

  void forEach(void action(element)) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      action(this[i]);
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
  }

  bool get isEmpty => length == 0;

  bool get isNotEmpty => !isEmpty;

  dynamic get first {
    if (length == 0) throw new StateError("No elements");
    return this[0];
  }

  dynamic get last {
    if (length == 0) throw new StateError("No elements");
    return this[length - 1];
  }

  dynamic get single {
    if (length == 0) throw new StateError("No elements");
    if (length > 1) throw new StateError("Too many elements");
    return this[0];
  }

  bool contains(Object element) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      if (this[i] == element) return true;
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    return false;
  }

  bool every(bool test(element)) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      if (!test(this[i])) return false;
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    return true;
  }

  bool any(bool test(element)) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      if (test(this[i])) return true;
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    return false;
  }

  dynamic firstWhere(bool test(element), { Object orElse() }) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      var element = this[i];
      if (test(element)) return element;
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    if (orElse != null) return orElse();
    throw new StateError("No matching element");
  }

  dynamic lastWhere(bool test(element), { Object orElse() }) {
    int length = this.length;
    for (int i = length - 1; i >= 0; i--) {
      var element = this[i];
      if (test(element)) return element;
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    if (orElse != null) return orElse();
    throw new StateError("No matching element");
  }

  singleWhere(bool test(element)) {
    int length = this.length;
    var match = null;
    bool matchFound = false;
    for (int i = 0; i < length; i++) {
      var element = this[i];
      if (test(element)) {
        if (matchFound) {
          throw new StateError("More than one matching element");
        }
        matchFound = true;
        var match = element;
      }
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    if (matchFound) return match;
    throw new StateError("No matching element");
  }

  String join([String separator = ""]) {
    int length = this.length;
    if (!separator.isEmpty) {
      if (length == 0) return "";
      String first = "${this[0]}";
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
      StringBuffer buffer = new StringBuffer(first);
      for (int i = 1; i < length; i++) {
        buffer.write(separator);
        buffer.write(this[i]);
        if (length != this.length) {
          throw new ConcurrentModificationError(this);
        }
      }
      return buffer.toString();
    } else {
      StringBuffer buffer = new StringBuffer();
      for (int i = 0; i < length; i++) {
        buffer.write(this[i]);
        if (length != this.length) {
          throw new ConcurrentModificationError(this);
        }
      }
      return buffer.toString();
    }
  }

  Iterable where(bool test(element)) =>
      new DataList.from(list.map((E) => E.value).where(test));

  Iterable map(f(element)) =>
      new DataList.from(list.map((E) => E.value).map(f));

  Iterable expand(Iterable f(element)) =>
      new DataList.from(list.map((E) => E.value).expand(f));

      reduce(combine(previousValue, element)) {
        if (length == 0) throw new StateError("No elements");
        var value = this[0];
        for (int i = 1; i < length; i++) {
          value = combine(value, this[i]);
        }
        return value;
      }

      fold(var initialValue, combine(var previousValue, element)) {
        var value = initialValue;
        int length = this.length;
        for (int i = 0; i < length; i++) {
          value = combine(value, this[i]);
          if (length != this.length) {
            throw new ConcurrentModificationError(this);
          }
        }
        return value;
      }

      Iterable skip(int count) => new DataList.from(list.map((E) => E.value).skip(count));

      Iterable skipWhile(bool test(element)) {
        return new DataList.from(list.map((E) => E.value).skipWhile(test));
      }

      Iterable take(int count) =>
          new DataList.from(list.map((E) => E.value).take(count));

      Iterable takeWhile(bool test(element)) =>
        new DataList.from(list.map((E) => E.value).takeWhile(test));

      List toList({ bool growable: true }) {
        List result;
        if (growable) {
          result = new List()..length = length;
        } else {
          result = new List(length);
        }
        for (int i = 0; i < length; i++) {
          result[i] = this[i];
        }
        return result;
      }

      Set toSet() {
        Set result = new DataCollection();
        for (int i = 0; i < length; i++) {
          result.add(this[i]);
        }
        return result;
      }

      void add(element, {author: null}) {
        _add(element);
        _notify(author: author);
      }

      void addAll(Iterable iterable, {author: null}) {
        for (dynamic element in iterable) {
          _add(element);
        }
        _notify(author: author);
      }

      bool remove(Object element, {author: null}) {
        int index = indexOf(element);
        if(index == -1) return false;
        var ret = _remove(_get(index));
        _notify(author: author);
        return ret;
      }

      bool _remove(DataReference element) {
        for (int i = 0; i < this.length; i++) {
          if (_get(i) == element) {
            _markChanged(length-1, new Change(_get(length-1), _get(i)));
            _markRemoved(length-1, _get(i));
            _changeSetSync.changedItems[length-1].oldValue = _get(i);
            _removeOnDataChangeListener(i);
            this._setRange(i, this.length - 1, list, i + 1);
            list.length -= 1;
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

      static void _filter(DataList source,
                          bool test(var element),
                          bool retainMatching) {
        int length = source.length;
        for (int i = length - 1; i >= 0; i--) {
          var element = source._get(i);
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

      void sort([int compare(a, b)]) {
        if (compare == null) {
          var defaultCompare = Comparable.compare;
          compare = defaultCompare;
        }
        for(int i=0; i < list.length; i++) {
          _markChanged(i, new Change(list[i], undefined));
        }
        var sorted = list.sort((a,b) => compare(a.value, b.value));
        for(int i=0; i < list.length; i++) {
          _markChanged(i, new Change(undefined, list[i]));
        }
        _notify();
      }

      void shuffle([Random random]) {
        if (random == null) random = new Random();
        int length = this.length;
        while (length > 1) {
          int pos = random.nextInt(length);
          length -= 1;
          var tmp = _get(length);
          _set(length, _get(pos));
          _set(pos, tmp);
        }
        _notify();
      }

      Map<int, dynamic> asMap() {
        return new Data.from(list.map((E) => E).toList().asMap());
      }

      void _rangeCheck(int start, int end) {
        if (start < 0 || start > this.length) {
          throw new RangeError.range(start, 0, this.length);
        }
        if (end < start || end > this.length) {
          throw new RangeError.range(end, start, this.length);
        }
      }

      List sublist(int start, [int end]) {
        if (end == null) end = this.length;
        _rangeCheck(start, end);
        int length = end - start;
        List result = new DataList()..length = length;
        for (int i = 0; i < length; i++) {
          result[i] = this[start + i];
        }
        return result;
      }

      Iterable getRange(int start, int end) {
        _rangeCheck(start, end);
        return new DataList.from(list.getRange(start, end).map((E) => E.value));
      }

      void removeRange(int start, int end, {author: null}) {
        _rangeCheck(start, end);
        int length = end - start;
        for(int i = end-1; i >= start; i--) _remove(_get(i));
        _notify(author: author);
      }

      void fillRange(int start, int end, [fill]) {
        _rangeCheck(start, end);
        for (int i = start; i < end; i++) {
          _set(i, new DataReference(fill));
        }
        _notify();
      }

      void setRange(int start, int end, Iterable iterable, [int skipCount = 0]) {
        _rangeCheck(start, end);
        for(var elem in iterable) {
          if(start < end) list[start].value = elem;
          start++;
        }
        _notify();
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
            this._setRange(insertEnd, newLength, list, end);
            this._length = newLength;
          }
        } else {
          int delta = insertLength - removeLength;
          int newLength = this.length + delta;
          int insertEnd = start + insertLength;  // aka. end + delta.
          this._length = newLength;
          this._setRange(insertEnd, newLength, list, end);
          this._setRange(start, insertEnd, newContents);
        }
        _notify(author: author);
      }

      int indexOf(Object element, [int startIndex = 0]) {
        if (startIndex >= this.length) {
          return -1;
        }
        if (startIndex < 0) {
          startIndex = 0;
        }
        for (int i = startIndex; i < this.length; i++) {
          if (this[i] == element) {
            return i;
          }
        }
        return -1;
      }

      /**
       * Returns the last index in the list [a] of the given [element], starting
       * the search at index [startIndex] to 0.
       * Returns -1 if [element] is not found.
       */
      int lastIndexOf(Object element, [int startIndex]) {
        if (startIndex == null) {
          startIndex = this.length - 1;
        } else {
          if (startIndex < 0) {
            return -1;
          }
          if (startIndex >= this.length) {
            startIndex = this.length - 1;
          }
        }
        for (int i = startIndex; i >= 0; i--) {
          if (this[i] == element) {
            return i;
          }
        }
        return -1;
      }

      void insert(int index, element, {author: null}) {
        if (index < 0 || index > length) {
          throw new RangeError.range(index, 0, length);
        }
        if (index == this.length) {
          _add(element);
          return;
        }
        // We are modifying the length just below the is-check. Without the check
        // Array.copy could throw an exception, leaving the list in a bad state
        // (with a length that has been increased, but without a new element).
        if (index is! int) throw new ArgumentError(index);
        this._length++;
        _setRange(index + 1, this.length, list, index);
        _set(index, new DataReference(element));
        _notify(author: author);
      }

      removeAt(int index, {author: null}) {
        var result = this[index];
        _remove(_get(index));
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
        _setRange(index + insertionLength, this.length, list, index);
        for (dynamic element in iterable) {
          _set(index++, new DataReference(element));
        }
        _notify(author: author);
      }

      void setAll(int index, Iterable iterable, {author: null}) {
        for (dynamic element in iterable) {
          list[index++].value = element;
        }
        _notify(author: author);
      }

      Iterable get reversed => new DataList.from(list.reversed.map((E) => E.value));

      String toString() {
        if (_toStringVisiting.contains(this)) {
          return '[...]';
        }

        var result = new StringBuffer();
        try {
          _toStringVisiting.add(this);
          result.write('[');
          result.writeAll(this, ', ');
          result.write(']');
        } finally {
          _toStringVisiting.remove(this);
        }

        return result.toString();
      }

      void dispose() {
        _dispose();
      }

}