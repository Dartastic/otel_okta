// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

/// OpenTelemetry instrumentation for Okta authentication operations.
///
/// Single helper `tracedOkta(...)` wraps any Okta auth call (signIn,
/// signOut, refreshToken, MFA factor enrollment / verification, ...)
/// in a CLIENT span carrying `okta.*` attributes (operation, issuer,
/// client_id, factor.type) plus `user.id` / `user.email`.
library;

export 'src/otel_okta.dart';
export 'src/otel_okta_suppression.dart';
