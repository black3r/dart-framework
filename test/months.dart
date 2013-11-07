// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library months_test;

import "package:clean_data/clean_data.dart";

Data january, february, march, april, may, june, july, august, september,
october, november, december;

DataCollection months, evenMonths, oddMonths;

setUpMonths() {
  january = new Data.fromMap({'name': 'January', 'days': 31, 'number': 1});
  february = new Data.fromMap({'name': 'February', 'days': 28, 'number': 2});
  march = new Data.fromMap({'name': 'March', 'days': 31, 'number': 3});
  april = new Data.fromMap({'name': 'April', 'days': 30, 'number': 4});
  may = new Data.fromMap({'name': 'May', 'days': 31, 'number': 5});
  june = new Data.fromMap({'name': 'June', 'days': 30, 'number': 6});
  july = new Data.fromMap({'name': 'July', 'days': 31, 'number': 7});
  august = new Data.fromMap({'name': 'August', 'days': 31, 'number': 8});
  september = new Data.fromMap({'name': 'September', 'days': 30, 'number': 9});
  october = new Data.fromMap({'name': 'October', 'days': 31, 'number': 10});
  november = new Data.fromMap({'name': 'November', 'days': 30, 'number': 11});
  december = new Data.fromMap({'name': 'December', 'days': 31, 'number': 12});

  months = new DataCollection.from([january, february, march, april, may, june,
    july, august, september, october, november, december]);

  evenMonths = new DataCollection.from(months.where((month) => month['number'] % 2 == 0));
  oddMonths = new DataCollection.from(months.where((month) => month['number'] % 2 == 1));
}