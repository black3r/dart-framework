// Copyright (c) 2013, Roman Hudec. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE
// file.

import 'test/model.dart';
import 'test/collection.dart';
import 'test/filteredcollection.dart';
import 'test/sortedcollection.dart';
import 'package:unittest/unittest.dart';

/**
 * Runs all tests
 */
void main() {
  test_collection();
  test_model();
  test_filteredcollection();  
  test_sortedcollection();
}