// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_okta_suppression.dart';

const _tracerName = 'dartastic_otel_libs_okta';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps an Okta authentication / management call in a CLIENT span.
///
/// Works with okta_flutter, the Okta Auth JS / Sign-In Widget via
/// platform channels, or direct calls to the Okta API — pass your
/// call inside [invoke]. Span name `okta <operation>`.
///
/// ```dart
/// final tokens = await tracedOkta<Tokens>(
///   operation: 'signIn',
///   factorType: 'password',
///   issuer: 'https://example.okta.com/oauth2/default',
///   clientId: 'CLIENT_X',
///   invoke: () => oktaClient.signIn(username, password),
///   onSuccessUserId: (t) => t.idTokenClaims.sub,
/// );
/// ```
Future<T> tracedOkta<T>({
  required String operation,
  required Future<T> Function() invoke,
  String? issuer,
  String? clientId,
  String? factorType,
  String? email,
  String? userId,
  String? Function(T)? onSuccessUserId,
}) async {
  if (oktaInstrumentationSuppressed()) return invoke();

  final m = <String, Object>{'okta.operation': operation};
  if (issuer != null) m['okta.issuer'] = issuer;
  if (clientId != null) m['okta.client_id'] = clientId;
  if (factorType != null) m['okta.factor.type'] = factorType;
  if (email != null) m[User.userEmail.key] = email;
  if (userId != null) m[User.userId.key] = userId;

  final span = _tracer().startSpan(
    'okta $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final result = await invoke();
    final uid = onSuccessUserId?.call(result);
    if (uid != null) {
      span.addAttributes(OTel.attributes([
        OTel.attributeString(User.userId.key, uid),
      ]));
    }
    return result;
  } catch (e, st) {
    span.addAttributes(
      OTel.attributes([
        OTel.attributeString(
          ErrorResource.errorType.key,
          e.runtimeType.toString(),
        ),
      ]),
    );
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
