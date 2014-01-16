// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library months_test;

import "package:clean_data/clean_data.dart";

DataMap january, february, march, april, may, june, july, august, september,
october, november, december;

DataSet months, evenMonths, oddMonths, spring, summer, autumn, winter;

setUpMonths() {
  january = new DataMap.from({'name': 'January', 'days': 31, 'number': 1});
  february = new DataMap.from({'name': 'February', 'days': 28, 'number': 2});
  march = new DataMap.from({'name': 'March', 'days': 31, 'number': 3});
  april = new DataMap.from({'name': 'April', 'days': 30, 'number': 4});
  may = new DataMap.from({'name': 'May', 'days': 31, 'number': 5});
  june = new DataMap.from({'name': 'June', 'days': 30, 'number': 6});
  july = new DataMap.from({'name': 'July', 'days': 31, 'number': 7});
  august = new DataMap.from({'name': 'August', 'days': 31, 'number': 8});
  september = new DataMap.from({'name': 'September', 'days': 30, 'number': 9});
  october = new DataMap.from({'name': 'October', 'days': 31, 'number': 10});
  november = new DataMap.from({'name': 'November', 'days': 30, 'number': 11});
  december = new DataMap.from({'name': 'December', 'days': 31, 'number': 12});

  months = new DataSet.from([january, february, march, april, may, june,
    july, august, september, october, november, december]);

  evenMonths = new DataSet.from(months.where((month) => month['number'] % 2 == 0));
  oddMonths = new DataSet.from(months.where((month) => month['number'] % 2 == 1));
  spring = new DataSet.from([march, april, may]);
  summer = new DataSet.from([june, july, august]);
  autumn = new DataSet.from([september, october, november]);
  winter = new DataSet.from([december, january, february]);

}

main(){
  print('begin');
  setUpMonths();
  print('end');
}