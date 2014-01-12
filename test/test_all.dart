// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


import 'data_test.dart' as data_test;
import 'data_collection_test.dart' as data_collection_test;
import 'data_reference_test.dart' as data_reference_test;
import 'hash_index_test.dart' as hash_index_test;
import 'change_set_test.dart' as change_set_test;
import 'change_streams_test.dart' as change_streams_test;

import 'collections/transformed_collection_view_test.dart' as transformed_test;
import 'collections/filtered_collection_view_test.dart' as filtered_test;
import 'collections/unioned_collection_view_test.dart' as unioned_test;
import 'collections/intersected_collection_view_test.dart' as intersected_test;
import 'collections/excepted_collection_view_test.dart' as excepted_test;
import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';

main() {
  run(new VMConfiguration());
}

run(configuration) {
  unittestConfiguration = configuration;

  data_test.main();
  data_collection_test.main();
  data_reference_test.main();
  change_streams_test.main();
  change_set_test.main();

  // collection views test
  transformed_test.main();
  filtered_test.main();
  unioned_test.main();
  intersected_test.main();
  excepted_test.main();
  hash_index_test.main();
}