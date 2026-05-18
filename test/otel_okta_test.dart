// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_okta/otel_okta.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_okta-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('signIn emits CLIENT span with okta.* + user attrs', () async {
    await tracedOkta<Map<String, String>>(
      operation: 'signIn',
      issuer: 'https://example.okta.com/oauth2/default',
      clientId: 'CLIENT_X',
      factorType: 'password',
      email: 'ada@example.com',
      invoke: () async => {'sub': 'user-42'},
      onSuccessUserId: (r) => r['sub'],
    );
    final span = spans.findSpanByName('okta signIn');
    expect(span, isNotNull);
    final a = attrsOf(span!);
    expect(a['okta.operation'], 'signIn');
    expect(a['okta.issuer'], 'https://example.okta.com/oauth2/default');
    expect(a['okta.client_id'], 'CLIENT_X');
    expect(a['okta.factor.type'], 'password');
    expect(a['user.email'], 'ada@example.com');
    expect(a['user.id'], 'user-42');
  });

  test('records exception on throw', () async {
    await expectLater(
      tracedOkta<String>(
        operation: 'signIn',
        invoke: () async => throw StateError('mfa_required'),
      ),
      throwsA(isA<StateError>()),
    );
    expect(spans.findSpanByName('okta signIn')!.status, SpanStatusCode.Error);
  });

  test('suppression skips the span', () async {
    await runWithoutOktaInstrumentationAsync(() async {
      await tracedOkta<String>(
        operation: 'signOut',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('okta '), isEmpty);
  });
}
