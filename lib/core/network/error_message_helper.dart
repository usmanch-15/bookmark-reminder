/// Converts raw exceptions into user-friendly messages.
/// Use this everywhere you catch an error before showing it in the UI.
class ErrorMessageHelper {
  static String from(Object error) {
    final String raw = error.toString().toLowerCase();

    if (raw.contains('socketexception') || raw.contains('failed host lookup')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (raw.contains('timeout')) {
      return 'The request took too long. Please try again.';
    }
    if (raw.contains('invalid login') || raw.contains('invalid credentials')) {
      return 'Incorrect email or password.';
    }
    if (raw.contains('email not confirmed')) {
      return 'Please verify your email before logging in.';
    }
    if (raw.contains('user already registered')) {
      return 'An account with this email already exists.';
    }
    if (raw.contains('row-level security') || raw.contains('permission denied')) {
      return 'You don\'t have permission to do this. Please log in again.';
    }
    if (raw.contains('jwt') || raw.contains('session')) {
      return 'Your session expired. Please log in again.';
    }
    return 'Something went wrong. Please try again.';
  }
}