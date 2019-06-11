// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Element diagnostics json includes widgetRuntimeType', () async {
    final Element element = _TestElement();

    final Map<String, Object> json = element.toDiagnosticsNode().toJsonMap(const DiagnosticsSerialisationDelegate());
    expect(json['widgetRuntimeType'], 'Placeholder');
    expect(json['stateful'], isFalse);
  });

  test('StatefulElement diganostics are stateful', () {
    final Element element = StatefulElement(const Tooltip(message: 'foo'));

    final Map<String, Object> json = element.toDiagnosticsNode().toJsonMap(const DiagnosticsSerialisationDelegate());
    expect(json['widgetRuntimeType'], 'Tooltip');
    expect(json['stateful'], isTrue);
  });

  group('Serialisation', () {
    final TestTree testTree = TestTree(
      properties: <DiagnosticsNode>[
        StringProperty('stringProperty1', 'value1', quoted: false),
        DoubleProperty('doubleProperty1', 42.5),
        DoubleProperty('roundedProperty', 1.0 / 3.0),
        StringProperty('DO_NOT_SHOW', 'DO_NOT_SHOW', level: DiagnosticLevel.hidden, quoted: false),
        DiagnosticsProperty<Object>('DO_NOT_SHOW_NULL', null, defaultValue: null),
        DiagnosticsProperty<Object>('nullProperty', null),
        StringProperty('node_type', '<root node>', showName: false, quoted: false),
      ],
      children: <TestTree>[
        TestTree(name: 'node A'),
        TestTree(
          name: 'node B',
          properties: <DiagnosticsNode>[
            StringProperty('p1', 'v1', quoted: false),
            StringProperty('p2', 'v2', quoted: false),
          ],
          children: <TestTree>[
            TestTree(name: 'node B1'),
            TestTree(
              name: 'node B2',
              properties: <DiagnosticsNode>[StringProperty('property1', 'value1', quoted: false)],
            ),
            TestTree(
              name: 'node B3',
              properties: <DiagnosticsNode>[
                StringProperty('node_type', '<leaf node>', showName: false, quoted: false),
                IntProperty('foo', 42),
              ],
            ),
          ],
        ),
        TestTree(
          name: 'node C',
          properties: <DiagnosticsNode>[
            StringProperty('foo', 'multi\nline\nvalue!', quoted: false),
          ],
        ),
      ],
    );

    test('default', () {
      final Map<String, Object> result = testTree.toDiagnosticsNode().toJsonMap(const DiagnosticsSerialisationDelegate());
      expect(result.containsKey('properties'), isFalse);
      expect(result.containsKey('children'), isFalse);
    });

    test('subtreeDepth 1', () {
      final Map<String, Object> result = testTree.toDiagnosticsNode().toJsonMap(const DiagnosticsSerialisationDelegate(subtreeDepth: 1));
      expect(result.containsKey('properties'), isFalse);
      final List<Map<String, Object>> children = result['children'];
      expect(children[0].containsKey('children'), isFalse);
      expect(children[1].containsKey('children'), isFalse);
      expect(children[2].containsKey('children'), isFalse);
    });

    test('subtreeDepth 5', () {
      final Map<String, Object> result = testTree.toDiagnosticsNode().toJsonMap(const DiagnosticsSerialisationDelegate(subtreeDepth: 5));
      expect(result.containsKey('properties'), isFalse);
      final List<Map<String, Object>> children = result['children'];
      expect(children[0]['children'], hasLength(0));
      expect(children[1]['children'], hasLength(3));
      expect(children[2]['children'], hasLength(0));
    });

    test('includeProperties', () {
      final Map<String, Object> result = testTree.toDiagnosticsNode().toJsonMap(const DiagnosticsSerialisationDelegate(includeProperties: true));
      expect(result.containsKey('children'), isFalse);
      expect(result['properties'], hasLength(7));
    });

    test('includeProperties with subtreedepth 1', () {
      final Map<String, Object> result = testTree.toDiagnosticsNode().toJsonMap(const DiagnosticsSerialisationDelegate(
        includeProperties: true,
        subtreeDepth: 1,
      ));
      expect(result['properties'], hasLength(7));
      final List<Map<String, Object>> children = result['children'];
      expect(children, hasLength(3));
      expect(children[0]['properties'], hasLength(0));
      expect(children[1]['properties'], hasLength(2));
      expect(children[2]['properties'], hasLength(1));
    });

    test('additionalNodeProperties', () {
      final Map<String, Object> result = testTree.toDiagnosticsNode().toJsonMap(DiagnosticsSerialisationDelegate(
        includeProperties: true,
        subtreeDepth: 1,
        additionalNodeProperties: (DiagnosticsNode node, DiagnosticsSerialisationDelegate delegate) {
          return <String, Object>{
            'foo': true,
          };
        }
      ));
      expect(result['foo'], isTrue);
      final List<Map<String, Object>> properties = result['properties'];
      expect(properties, hasLength(7));
      expect(properties.every((Map<String, Object> property) => property['foo'] == true), isTrue);

      final List<Map<String, Object>> children = result['children'];
      expect(children, hasLength(3));
      expect(children.every((Map<String, Object> child) => child['foo'] == true), isTrue);
    });

    test('filterProperties - sublist', () {
      final Map<String, Object> result = testTree.toDiagnosticsNode().toJsonMap(DiagnosticsSerialisationDelegate(
          includeProperties: true,
          filterProperties: (List<DiagnosticsNode> nodes, DiagnosticsNode owner, DiagnosticsSerialisationDelegate delegate) {
            return nodes.whereType<StringProperty>().toList();
          }
      ));
      final List<Map<String, Object>> properties = result['properties'];
      expect(properties, hasLength(3));
      expect(properties.every((Map<String, Object> property) => property['type'] == 'StringProperty'), isTrue);
    });

    test('filterProperties - replace', () {
      bool replaced = false;
      final Map<String, Object> result = testTree.toDiagnosticsNode().toJsonMap(DiagnosticsSerialisationDelegate(
          includeProperties: true,
          filterProperties: (List<DiagnosticsNode> nodes, DiagnosticsNode owner, DiagnosticsSerialisationDelegate delegate) {
            if (replaced) {
              return nodes;
            }
            replaced = true;
            return <DiagnosticsNode>[
              StringProperty('foo', 'bar'),
            ];
          }
      ));
      final List<Map<String, Object>> properties = result['properties'];
      expect(properties, hasLength(1));
      expect(properties.single['name'], 'foo');
    });

    test('filterChildren - sublist', () {
      final Map<String, Object> result = testTree.toDiagnosticsNode().toJsonMap(DiagnosticsSerialisationDelegate(
          subtreeDepth: 1,
          filterChildren: (List<DiagnosticsNode> nodes, DiagnosticsNode owner, DiagnosticsSerialisationDelegate delegate) {
            return nodes.where((DiagnosticsNode node) => node.getProperties().isEmpty).toList();
          }
      ));
      final List<Map<String, Object>> children = result['children'];
      expect(children, hasLength(1));
    });

    test('filterChildren - replace', () {
      final Map<String, Object> result = testTree.toDiagnosticsNode().toJsonMap(DiagnosticsSerialisationDelegate(
          subtreeDepth: 1,
          filterChildren: (List<DiagnosticsNode> nodes, DiagnosticsNode owner, DiagnosticsSerialisationDelegate delegate) {
            final List<DiagnosticsNode> result = <DiagnosticsNode>[];
            for (DiagnosticsNode node in nodes) {
              result.addAll(node.getChildren());
            }
            return result;
          }
      ));
      final List<Map<String, Object>> children = result['children'];
      expect(children, hasLength(3));
      expect(children.first['name'], 'child node B1');
    });

    test('nodeTruncator', () {
      final Map<String, Object> result = testTree.toDiagnosticsNode().toJsonMap(DiagnosticsSerialisationDelegate(
          subtreeDepth: 5,
          includeProperties: true,
          nodeTruncator: (List<DiagnosticsNode> nodes, DiagnosticsNode owner, DiagnosticsSerialisationDelegate delegate) {
            return nodes.take(2).toList();
          }
      ));
      final List<Map<String, Object>> children = result['children'];
      expect(children, hasLength(3));
      expect(children.last['truncated'], isTrue);

      final List<Map<String, Object>> properties = result['properties'];
      expect(properties, hasLength(3));
      expect(properties.last['truncated'], isTrue);
    });

    test('delegateForAddingNodes', () {
      final Map<String, Object> result = testTree.toDiagnosticsNode().toJsonMap(DiagnosticsSerialisationDelegate(
          subtreeDepth: 5,
          includeProperties: true,
          delegateForAddingNode: (DiagnosticsNode node, DiagnosticsSerialisationDelegate delegate) {
            return delegate.copyWith(includeProperties: false);
          }
      ));
      final List<Map<String, Object>> properties = result['properties'];
      expect(properties, hasLength(7));
      expect(properties.every((Map<String, Object> property) => !property.containsKey('properties')), isTrue);

      final List<Map<String, Object>> children = result['children'];
      expect(children, hasLength(3));
      expect(children.every((Map<String, Object> child) => !child.containsKey('properties')), isTrue);
    });
  });
}

class _TestElement extends Element {
  _TestElement() : super(const Placeholder());

  @override
  void forgetChild(Element child) {
    // Intentionally left empty.
  }

  @override
  void performRebuild() {
    // Intentionally left empty.
  }
}

class TestTree extends Object with DiagnosticableTreeMixin {
  TestTree({
    this.name,
    this.style,
    this.children = const <TestTree>[],
    this.properties = const <DiagnosticsNode>[],
  });

  final String name;
  final List<TestTree> children;
  final List<DiagnosticsNode> properties;
  final DiagnosticsTreeStyle style;

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[];
    for (TestTree child in this.children) {
      children.add(child.toDiagnosticsNode(
        name: 'child ${child.name}',
        style: child.style,
      ));
    }
    return children;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    if (style != null)
      properties.defaultDiagnosticsTreeStyle = style;

    this.properties.forEach(properties.add);
  }
}
