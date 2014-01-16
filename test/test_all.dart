// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


import 'data_map_test.dart' as data_map_test;
import 'data_list_test.dart' as data_list_test;
import 'data_set_test.dart' as data_set_test;
import 'data_reference_test.dart' as data_reference_test;
import 'hash_index_test.dart' as hash_index_test;
import 'change_set_test.dart' as change_set_test;
import 'set_streams_test.dart' as set_streams_test;
import 'cleanify_test.dart' as cleanify_test;

import 'data_sets/transformed_set_view_test.dart' as transformed_test;
import 'data_sets/filtered_set_view_test.dart' as filtered_test;
import 'data_sets/unioned_set_view_test.dart' as unioned_test;
import 'data_sets/intersected_set_view_test.dart' as intersected_test;
import 'data_sets/excepted_set_view_test.dart' as excepted_test;
import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';

main() {
  run(new VMConfiguration());
}

run(configuration) {
  unittestConfiguration = configuration;

  data_map_test.main();
  data_list_test.main();
  data_set_test.main();
  data_reference_test.main();
  set_streams_test.main();
  change_set_test.main();

  // set views test
  transformed_test.main();
  filtered_test.main();
  unioned_test.main();
  intersected_test.main();
  excepted_test.main();
  hash_index_test.main();
  
  cleanify_test.main();
}
