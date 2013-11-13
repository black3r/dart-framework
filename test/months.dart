// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library months_test;

import "package:clean_data/clean_data.dart";

Data january, february, march, april, may, june, july, august, september,
october, november, december;

DataCollection months, evenMonths, oddMonths;

setUpMonths() {
  january = new Data.from({'name': 'January', 'days': 31, 'number': 1});
  february = new Data.from({'name': 'February', 'days': 28, 'number': 2});
  march = new Data.from({'name': 'March', 'days': 31, 'number': 3});
  april = new Data.from({'name': 'April', 'days': 30, 'number': 4});
  may = new Data.from({'name': 'May', 'days': 31, 'number': 5});
  june = new Data.from({'name': 'June', 'days': 30, 'number': 6});
  july = new Data.from({'name': 'July', 'days': 31, 'number': 7});
  august = new Data.from({'name': 'August', 'days': 31, 'number': 8});
  september = new Data.from({'name': 'September', 'days': 30, 'number': 9});
  october = new Data.from({'name': 'October', 'days': 31, 'number': 10});
  november = new Data.from({'name': 'November', 'days': 30, 'number': 11});
  december = new Data.from({'name': 'December', 'days': 31, 'number': 12});

  months = new DataCollection.from([january, february, march, april, may, june,
    july, august, september, october, november, december]);

  evenMonths = new DataCollection.from(months.where((month) => month['number'] % 2 == 0));
  oddMonths = new DataCollection.from(months.where((month) => month['number'] % 2 == 1));
}