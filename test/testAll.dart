// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


import 'data_test.dart' as DataTest;
import 'data_collection_test.dart' as DataCollectionTest;
import 'hash_index_test.dart' as HashIndexTest;
import 'id_generator_test.dart' as IdGeneratorTest;
import 'change_set_test.dart' as ChangeSetTest;

import 'collections/filtered_collection_view_test.dart' as FilteredViewCollectionTest;
import 'collections/mapped_collection_view_test.dart' as MappedCollectionViewTest;
import 'collections/unioned_collection_view_test.dart' as UnionedCollectionViewTest;
import 'collections/intersected_collection_view_test.dart' as IntersectedCollectionViewTest;
import 'collections/excepted_collection_view_test.dart' as ExceptedCollectionViewTest;

main() {

  DataTest.main();
  DataCollectionTest.main();
  IdGeneratorTest.main();
  ChangeSetTest.main();

  // collection views test
  FilteredViewCollectionTest.main();
  MappedCollectionViewTest.main();
  UnionedCollectionViewTest.main();
  IntersectedCollectionViewTest.main();
  ExceptedCollectionViewTest.main();
  HashIndexTest.main();
}