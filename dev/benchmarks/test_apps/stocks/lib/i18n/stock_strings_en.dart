// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'stock_strings.dart';

/// The translations for English (`en`).
class StockStringsEn extends StockStrings {
  StockStringsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Stocks';

  @override
  String get market => 'MARKET';

  @override
  String get portfolio => 'PORTFOLIO';
}

/// The translations for English, as used in the United States (`en_US`).
class StockStringsEnUs extends StockStringsEn {
  StockStringsEnUs(): super('en_US');

  @override
  String get title => 'Stocks';

  @override
  String get market => 'MARKET';

  @override
  String get portfolio => 'PORTFOLIO';
}
