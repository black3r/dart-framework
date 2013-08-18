// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Abstract Class that handles Child-Parent communication between [Collection]s.
 */
abstract class ChildCollection extends Collection {
  final Collection parent;

  /**
   * Creates a [ChildCollection] that is child of parent [Collection]
   * and fills it with models from parent collection.
   */
  ChildCollection(this.parent) : super() {
    this.parent.onChange.listen((event) => this.update());
  }

  /**
   * Recalculate the collection from the parent data.
   */
  void update({silent: false});

  void add(Model model, {silent: false}) {
    throw new UnsupportedError('This is read only collection.');
  }

  void remove(id, {silent: false}) {
    throw new UnsupportedError('This is read only collection.');
  }

  void clear({silent: false}) {
    throw new UnsupportedError('This is read only collection.');
  }
}