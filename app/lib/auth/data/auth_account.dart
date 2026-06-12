/// Account validation status, mirrored from the API `users.status` field.
enum AccountStatus { pending, approved, rejected }

/// Parses the API status string. Unknown / missing values fail closed to
/// [AccountStatus.pending] so a malformed response never grants access.
AccountStatus accountStatusFromString(String? value) {
  switch (value) {
    case 'approved':
      return AccountStatus.approved;
    case 'rejected':
      return AccountStatus.rejected;
    default:
      return AccountStatus.pending;
  }
}

/// Minimal projection of the `/auth/sync` response needed to drive the
/// approval gate. The full profile is loaded separately once approved.
class AuthSyncResult {
  final String id;
  final AccountStatus status;

  const AuthSyncResult({required this.id, required this.status});

  factory AuthSyncResult.fromJson(Map<String, dynamic> json) => AuthSyncResult(
    id: json['id'] as String? ?? '',
    status: accountStatusFromString(json['status'] as String?),
  );
}
