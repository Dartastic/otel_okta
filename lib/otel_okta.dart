// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

/// OpenTelemetry instrumentation for Okta authentication operations.
///
/// Single helper `tracedOkta(...)` wraps any Okta auth call (signIn,
/// signOut, refreshToken, MFA factor enrollment / verification, ...)
/// in a CLIENT span carrying `okta.*` attributes (operation, issuer,
/// client_id, factor.type) plus `user.id` / `user.email`.
library;

export 'src/otel_okta.dart';
export 'src/otel_okta_suppression.dart';
