# Password Recovery Implementation Guide

## Overview
This implementation provides a complete **Forgot Password** feature with **Email OTP (One-Time Password)** verification for the UEMS (Unified Education Management System) project.

## Features Implemented

### ✅ Complete Password Recovery Flow
1. **Forgot Password Screen** - User enters their User ID
2. **OTP Verification Screen** - User enters the 6-digit OTP sent to their email
3. **Password Reset Screen** - User sets a new password with strength indicator
4. **Success Confirmation** - User receives confirmation and returns to login

### ✅ Security Features
- **OTP Expiry**: OTPs expire after 5 minutes
- **Masked Email Display**: User's email is partially hidden for privacy (e.g., `st***@uems.edu`)
- **Password Strength Indicator**: Real-time feedback on password strength
- **Resend OTP**: Users can request a new OTP with a 60-second cooldown
- **Auto-verification**: OTP is automatically verified when all 6 digits are entered

### ✅ User Experience Features
- Beautiful animations and transitions
- Loading states for all async operations
- Clear error messages
- Responsive design (mobile and desktop)
- Consistent violet theme matching the login page

## Files Created

### 1. Services
- **`lib/services/auth_service.dart`** - Handles authentication logic, OTP generation, and user management
- **`lib/services/email_service.dart`** - Manages email sending (currently simulated for development)

### 2. Views
- **`lib/views/forgot_password_view.dart`** - Initial screen where users enter their User ID
- **`lib/views/verify_otp_view.dart`** - OTP input and verification screen
- **`lib/views/reset_password_view.dart`** - New password creation screen

### 3. Modified Files
- **`lib/views/login_view.dart`** - Connected "Forgot Password?" button to the new flow

## How It Works

### 1. User Flow
```
Login Screen
    ↓
[Forgot Password?] clicked
    ↓
Enter User ID → Send OTP
    ↓
Check Email (OTP displayed in console for development)
    ↓
Enter 6-digit OTP
    ↓
Create New Password
    ↓
Success! → Back to Login
```

### 2. Test Users (Mock Database)
The following test users are configured in `auth_service.dart`:

| User ID | Email | Role |
|---------|-------|------|
| 123 | student@uems.edu | student |
| 456 | admin@uems.edu | admin |
| 789 | teacher@uems.edu | teacher |

### 3. Testing the Feature

#### Step 1: Start the Application
```bash
flutter run -d windows
```

#### Step 2: Test Password Recovery
1. Click **"Forgot Password?"** on the login screen
2. Enter a User ID (e.g., `123`)
3. Click **"Send OTP"**
4. Check the console/terminal for the OTP (it will be printed there)
5. Enter the 6-digit OTP
6. Create a new password (minimum 6 characters)
7. Confirm the password
8. Click **"Reset Password"**
9. Success dialog appears - click **"Back to Login"**

#### Example Console Output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📧 EMAIL SENT (SIMULATED)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
To: student@uems.edu
Subject: Your UEMS Password Reset OTP

Hi Student User,

Your OTP for password reset is:

    ╔════════════════╗
    ║   123456   ║
    ╚════════════════╝

This OTP will expire in 5 minutes.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Production Setup

### Current State (Development/Demo)
The current implementation uses:
- **Mock user database** (in-memory)
- **Simulated email sending** (console output)
- **In-memory OTP storage**

### For Production Deployment

#### 1. Database Integration
Replace the mock user database in `auth_service.dart`:

```dart
// Current (Mock)
final Map<String, UserData> _userDatabase = {...};

// Production (Example with your backend)
Future<UserData?> _getUserById(String userId) async {
  final response = await http.get(
    Uri.parse('https://your-backend.com/api/users/$userId'),
  );
  if (response.statusCode == 200) {
    return UserData.fromJson(jsonDecode(response.body));
  }
  return null;
}
```

#### 2. Email Service Integration
Choose and integrate a real email service provider:

##### Option A: SendGrid
```yaml
# pubspec.yaml
dependencies:
  http: ^1.1.0
```

```dart
// lib/services/email_service.dart
Future<bool> sendOTPEmail({...}) async {
  final response = await http.post(
    Uri.parse('https://api.sendgrid.com/v3/mail/send'),
    headers: {
      'Authorization': 'Bearer YOUR_SENDGRID_API_KEY',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'personalizations': [
        {
          'to': [{'email': recipientEmail}],
        }
      ],
      'from': {'email': 'noreply@uems.edu'},
      'subject': 'Your UEMS Password Reset OTP',
      'content': [
        {
          'type': 'text/html',
          'value': '<h1>Your OTP is: $otp</h1>',
        }
      ],
    }),
  );
  return response.statusCode == 202;
}
```

##### Option B: Firebase Cloud Functions
```javascript
// Firebase Cloud Function
exports.sendOTPEmail = functions.https.onCall(async (data, context) => {
  const { email, otp, name } = data;
  
  const mailOptions = {
    from: 'UEMS <noreply@uems.edu>',
    to: email,
    subject: 'Your UEMS Password Reset OTP',
    html: `
      <h2>Hi ${name},</h2>
      <p>Your OTP for password reset is:</p>
      <h1 style="color: #8B5CF6;">${otp}</h1>
      <p>This OTP will expire in 5 minutes.</p>
    `,
  };
  
  await mailTransport.sendMail(mailOptions);
  return { success: true };
});
```

##### Option C: Backend API
```dart
// Call your backend API
final response = await http.post(
  Uri.parse('https://your-backend.com/api/send-otp'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'email': recipientEmail,
    'name': recipientName,
    'otp': otp,
  }),
);
```

#### 3. Secure OTP Storage
Use a secure backend or database:

```dart
// Store OTP in your backend
Future<void> _storeOTP(String userId, String otp, DateTime expiry) async {
  await http.post(
    Uri.parse('https://your-backend.com/api/otp/store'),
    body: jsonEncode({
      'userId': userId,
      'otp': otp,
      'expiry': expiry.toIso8601String(),
    }),
  );
}

// Verify OTP through backend
Future<bool> _verifyOTP(String userId, String otp) async {
  final response = await http.post(
    Uri.parse('https://your-backend.com/api/otp/verify'),
    body: jsonEncode({
      'userId': userId,
      'otp': otp,
    }),
  );
  return response.statusCode == 200;
}
```

#### 4. Password Hashing
Implement proper password hashing (never store plain text passwords):

```yaml
# pubspec.yaml
dependencies:
  crypto: ^3.0.3
```

```dart
import 'package:crypto/crypto.dart';
import 'dart:convert';

String hashPassword(String password) {
  final bytes = utf8.encode(password);
  final hash = sha256.convert(bytes);
  return hash.toString();
}
```

## Customization Options

### 1. Change OTP Length
In `verify_otp_view.dart`, change the number of input fields:
```dart
final List<TextEditingController> _otpControllers = List.generate(
  4, // Change from 6 to 4 for 4-digit OTP
  (index) => TextEditingController(),
);
```

### 2. Adjust OTP Expiry Time
In `auth_service.dart`:
```dart
final expiryTime = DateTime.now().add(const Duration(minutes: 10)); // Change from 5 to 10 minutes
```

### 3. Modify Resend Cooldown
In `verify_otp_view.dart`:
```dart
void _startResendTimer() {
  setState(() {
    _resendCountdown = 120; // Change from 60 to 120 seconds
  });
  // ...
}
```

### 4. Customize Email Template
Edit the email format in `email_service.dart`:
```dart
print('Subject: Your Custom Subject');
print('Your custom email body...');
```

### 5. Add More Password Requirements
In `reset_password_view.dart`, add validation:
```dart
if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
  return 'Password must contain a special character';
}
```

## Security Best Practices

### ✅ Implemented
- OTP expiry (5 minutes)
- Email masking for privacy
- Single OTP per user (overwrites previous)
- Connection to existing login system

### 📋 Todo for Production
- [ ] Implement rate limiting (prevent OTP spam)
- [ ] Add CAPTCHA to prevent automated attacks
- [ ] Use HTTPS for all API calls
- [ ] Implement password hashing (bcrypt, argon2)
- [ ] Add session management
- [ ] Store OTPs securely (encrypted database)
- [ ] Log security events (failed attempts, password changes)
- [ ] Implement 2FA as an additional layer
- [ ] Add email verification for new email addresses

## Troubleshooting

### Issue: "User ID not found"
**Solution**: Check that the User ID exists in the mock database or your production database.

### Issue: "OTP has expired"
**Solution**: Request a new OTP using the "Resend OTP" button.

### Issue: Console doesn't show OTP
**Solution**: 
1. Check your terminal/console window
2. Look for the decorative box with the OTP
3. Make sure Flutter is running in debug mode

### Issue: Navigation not working
**Solution**: Ensure all view files are properly imported in their parent files.

## Next Steps

### Immediate (Development)
1. Test all user flows with different User IDs
2. Verify error handling works correctly
3. Test on different screen sizes

### Before Production
1. Set up a real email service (SendGrid, AWS SES, etc.)
2. Connect to your user database
3. Implement password hashing
4. Add rate limiting
5. Set up proper backend API

### Future Enhancements
- [ ] Add SMS OTP as an alternative
- [ ] Implement "Remember Me" functionality
- [ ] Add password history (prevent reuse)
- [ ] Multi-language support
- [ ] Accessibility improvements (screen readers)
- [ ] Add analytics tracking

## Support

For questions or issues:
1. Check the console output for detailed error messages
2. Verify all imports are correct
3. Ensure Flutter SDK is up to date
4. Review the test user credentials

## Demo Script

Use this script to demonstrate the feature:

```
1. "Let me show you our new password recovery feature."
2. Click "Forgot Password?" button
3. "Users enter their User ID here" - enter '123'
4. "The system sends an OTP to their registered email"
5. Check console - "Here's the OTP in the email (simulated)"
6. "Users enter the 6-digit code" - enter the OTP from console
7. "Now they create a secure new password" - show strength indicator
8. Enter matching passwords
9. "Success! They can now log in with their new password"
```

---

**Version**: 1.0  
**Last Updated**: February 24, 2026  
**Status**: Development (Production-ready with email service integration)
