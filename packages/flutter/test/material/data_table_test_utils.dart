// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class Dessert {
  Dessert(this.name, this.calories, this.fat, this.carbs, this.protein, this.sodium, this.calcium, this.iron);

  final String name;
  final int calories;
  final double fat;
  final int carbs;
  final double protein;
  final int sodium;
  final int calcium;
  final int iron;
}

final List<Dessert> kDesserts = <Dessert>[
  new Dessert('FY',  159,  6.0,  24,  4.0,  87, 14,  1),
  new Dessert('ICS', 237,  9.0,  37,  4.3, 129,  8,  1),
  new Dessert('E',   262, 16.0,  24,  6.0, 337,  6,  7),
  new Dessert('C',   305,  3.7,  67,  4.3, 413,  3,  8),
  new Dessert('G',   356, 16.0,  49,  3.9, 327,  7, 16),
  new Dessert('JB',  375,  0.0,  94,  0.0,  50,  0,  0),
  new Dessert('L',   392,  0.2,  98,  0.0,  38,  0,  2),
  new Dessert('H',   408,  3.2,  87,  6.5, 562,  0, 45),
  new Dessert('D',   452, 25.0,  51,  4.9, 326,  2, 22),
  new Dessert('KK',  518, 26.0,  65,  7.0,  54, 12,  6),
];
