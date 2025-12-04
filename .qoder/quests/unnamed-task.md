# BodyTalk AI - Critical Fixes and Feature Implementation Plan

## Objective

This design document addresses specific functional issues and missing features in the BodyTalk AI application that were marked as completed in the project plan but are not working in the actual deployed application.

---

## Critical Issues Identified

### Authentication System Issues
1. Password reset flow not functional in the app
2. Google Sign-In not visible or working
3. Apple Sign-In not implemented for iOS/macOS
4. Biometric authentication (Face ID/Fingerprint) not functioning clearly

### Localization Issues
5. Mixed language texts appearing when switching languages
6. AI advice showing reversed language logic
7. Hard-coded Arabic strings in multiple pages
8. Food analysis labels not translating properly

### Subscription System Issues
9. Subscription system disappeared from current version
10. No visible subscription status in profile

---

## Design Solutions - Priority Ordered

### Phase 1: Authentication System Fixes (Critical)

#### 1.1 Password Reset Flow Implementation
**Current Status**: Password reset dialog exists in login_page.dart but workflow is incomplete

**Required Implementation**:

**Frontend (Flutter)**:
- Forgot Password link: Already visible on login page (line 602-613 in login_page.dart)
- Dialog implementation: Already exists (_showForgotPasswordDialog method)
- API call: Already implemented (ApiService.requestPasswordReset)
- User flow: Dialog → Email input → API call → Success/error message

**Backend (FastAPI)**:
- Endpoint: `/auth/forgot-password` (already exists in main.py line 152-180)
- Current behavior: Returns success message simulation
- Required enhancement: Generate password reset token and email sending

**Complete Workflow Design**:

1. User clicks "Forgot password?" on login screen
2. Dialog opens requesting email address
3. User enters email and clicks Send
4. Frontend calls `/auth/forgot-password` with email payload
5. Backend validates email existence
6. Backend generates secure reset token (JWT with 15-minute expiration)
7. Backend sends email with reset link containing token
8. User clicks link in email
9. User redirected to password reset page with token
10. User enters new password
11. Frontend calls `/auth/reset-password` with token and new password
12. Backend validates token and updates password
13. Success message shown, user can login with new password

**Required Backend Enhancements**:
- Token generation using JWT with short expiration
- Email service integration (SendGrid, AWS SES, or SMTP)
- Password reset confirmation endpoint
- Token validation and password update logic

**Security Considerations**:
- Reset tokens expire after 15 minutes
- One-time use tokens (invalidated after password change)
- Rate limiting on reset requests (max 3 per hour per email)
- Email verification before sending reset link
- Secure password requirements enforced

**Testing Requirements**:
- Test complete flow on physical device
- Verify email delivery
- Test token expiration handling
- Test invalid token rejection
- Test rate limiting

---

#### 1.2 Google Sign-In Implementation
**Current Status**: Social auth service exists (social_auth_service.dart) but button not visible on login page

**Required Implementation**:

**Frontend (Flutter)**:
- Add Google Sign-In button to login page below biometric button
- Button design: White background with Google logo icon
- Button label: "Continue with Google" (localized)
- Integration with SocialAuthService.signInWithGoogle()

**Button Placement Strategy**:
- Position: After Face ID/Biometric button, before "Don't have account" text
- Styling: Match app design language with white background and Google brand colors
- Icon: Official Google "G" logo
- Localization: Use BodyTalkApp.tr for button text

**Authentication Flow**:

1. User taps "Continue with Google" button
2. Frontend calls SocialAuthService.signInWithGoogle()
3. Google Sign-In dialog appears (account selection)
4. User selects Google account
5. Service retrieves idToken and user info
6. Frontend calls ApiService.socialLogin() with:
   - provider: 'google'
   - idToken: from Google
   - email: user's email
   - name: user's display name
   - photoUrl: profile picture URL
7. Backend validates Google token
8. Backend creates/retrieves user account
9. Backend returns JWT access token
10. Frontend stores token and navigates to main navigation
11. Success message displayed

**Backend Social Login Endpoint** (`/auth/social-login`):
- Input validation for provider type
- Google token verification using Google API
- User lookup by email
- User creation if new (auto-generate password)
- JWT token generation
- Return access token and user data

**Error Handling**:
- User cancellation: Show info message "Sign-in cancelled"
- Network error: Show error "Unable to connect to Google. Check internet connection"
- Token validation failure: Show error "Google authentication failed. Please try again"
- Backend error: Show generic error with retry option

**Dependencies**:
- google_sign_in package (already in pubspec.yaml)
- Backend Google OAuth2 verification library

**Testing Requirements**:
- Test on physical Android device
- Test on physical iOS device
- Test account selection flow
- Test with multiple Google accounts
- Test cancellation handling
- Test network failure scenarios
- Verify token storage and session persistence

---

#### 1.3 Apple Sign-In Implementation (iOS/macOS Only)
**Current Status**: Apple Sign-In service exists in social_auth_service.dart but not exposed in UI

**Required Implementation**:

**Platform Detection**:
- Use Platform.isIOS || Platform.isMacOS to conditionally show button
- Button must NOT appear on Android or other platforms
- Prevents app crashes on unsupported platforms

**Frontend (Flutter)**:
- Add Apple Sign-In button conditionally for iOS/macOS
- Button design: Black background with Apple logo
- Button label: "Continue with Apple" (localized)
- Integration with SocialAuthService.signInWithApple()

**Button Implementation Pattern**:
```
if (Platform.isIOS || Platform.isMacOS) {
  // Show Apple Sign-In button
  // Use official Apple design guidelines
  // Black button with white Apple logo
}
```

**Authentication Flow**:

1. User taps "Continue with Apple" button (iOS/macOS only)
2. Frontend calls SocialAuthService.signInWithApple()
3. Apple authentication dialog appears
4. User authenticates with Face ID/Touch ID/Password
5. Service retrieves Apple identity token and user info
6. Frontend calls ApiService.socialLogin() with:
   - provider: 'apple'
   - idToken: Apple identity token
   - email: user's email (if shared)
   - name: user's name (if shared)
   - userId: Apple user identifier
7. Backend validates Apple token
8. Backend creates/retrieves user account
9. Backend returns JWT access token
10. Frontend stores token and navigates to main navigation

**Privacy Considerations**:
- Apple allows users to hide email (private relay email)
- First time: User can choose to share or hide email
- Subsequent times: No name/email provided (only userIdentifier)
- Backend must handle missing email gracefully
- Store userIdentifier as primary lookup key

**Backend Apple Token Validation**:
- Verify token signature using Apple's public keys
- Validate token issuer and audience
- Check token expiration
- Extract user identifier
- Handle private email relay addresses

**Error Handling**:
- User cancellation: Show info message
- Platform not supported: Button not visible
- Token validation failure: Show error message
- Missing required data: Graceful fallback

**App Store Requirements**:
- Apple Sign-In must be enabled in Apple Developer account
- App ID must have Sign in with Apple capability
- Entitlements must be configured

**Testing Requirements**:
- Test on physical iPhone
- Test on macOS device
- Verify button does NOT appear on Android
- Test with email sharing enabled
- Test with email hiding enabled
- Test repeat sign-ins
- Verify private relay email handling

---

#### 1.4 Biometric Authentication (Face ID / Fingerprint)
**Current Status**: Face auth service exists (face_auth_service.dart) and login button exists but flow unclear

**Problem Analysis**:
- Biometric button visible on login page (line 644-667 in login_page.dart)
- _loginWithFace() method exists but requires prior token storage
- No clear enable/disable mechanism for biometric login
- No user preference toggle
- Confusing user experience (when does it work?)

**Required Implementation Strategy**:

**First-Time Login Flow**:
1. User logs in successfully with email/password
2. After successful login, show dialog: "Enable biometric login for faster access?"
3. If user accepts:
   - Store preference "biometric_enabled": true
   - Token already saved by ApiService
   - Show success message
4. If user declines:
   - Store preference "biometric_enabled": false
   - Continue to app

**Subsequent Login Flow**:
1. User opens app
2. Check if biometric_enabled == true AND token exists
3. If yes:
   - Automatically show biometric prompt immediately
   - On success: Navigate to main navigation
   - On failure: Show email/password login form
4. If no:
   - Show standard login form

**Biometric Button Behavior**:
- Button visible only when biometric_enabled == true
- Button disabled if no token stored
- Tapping button triggers biometric prompt
- Success: Navigate to app
- Failure: Show error message, user can retry

**Settings Integration**:
- Add toggle in Profile page under Security section
- "Enable biometric login"
- Toggling ON:
  - Trigger biometric prompt for confirmation
  - On success: Enable feature
  - On failure: Keep disabled
- Toggling OFF:
  - Disable biometric login
  - User must use email/password next time

**Security Considerations**:
- Biometric authentication confirms identity only
- Still validates stored JWT token with backend
- If token expired: Prompt for email/password login
- No password stored locally (only token)
- Biometric failure threshold: 3 attempts, then require password

**User Experience Flow**:

**Auto-Biometric on App Open**:
- If enabled and token valid: Show biometric prompt immediately
- Faster login experience
- Fallback to manual login if biometric fails

**Manual Biometric Button**:
- If user dismisses auto-prompt: Button available to retry
- Visual indicator that biometric is available
- Alternative to typing password

**Platform Support**:
- iOS: Face ID and Touch ID
- Android: Fingerprint, Face Unlock, Pattern
- Use local_auth package capabilities

**Testing Requirements**:
- Test on iPhone with Face ID
- Test on Android with fingerprint
- Test enable/disable toggle
- Test token expiration handling
- Test biometric failure scenarios
- Test with multiple app restarts
- Verify auto-prompt appears immediately on app open
- Test manual button when auto-prompt dismissed

---

### Phase 2: Localization System Fixes (Critical)

#### 2.1 Unified Localization Architecture
**Current Problem**: Mixed languages appearing across the app when switching language

**Root Cause Analysis**:
1. Hard-coded Arabic strings in multiple files
2. Inconsistent use of BodyTalkApp.tr() helper
3. Some strings not localized at all
4. Backend AI advice not respecting language selection

**Affected Areas**:
- Body analysis page (AI advice, labels)
- Food analysis page (nutritional labels, cuisine names)
- Profile page (entire page has hard-coded Arabic)
- Result displays
- Error messages

**Solution Architecture**:

**Frontend Localization Strategy**:

**Principle**: ALL user-facing text must use BodyTalkApp.tr() without exception

**BodyTalkApp.tr() Helper** (already exists in main.dart line 37-41):
- Centralized translation function
- Parameters: context, en, fr, ar
- Returns text based on current locale code
- Must be used for EVERY string shown to user

**Implementation Pattern**:
```
Text(
  BodyTalkApp.tr(
    context,
    en: 'English text',
    fr: 'Texte français',
    ar: 'نص عربي',
  ),
)
```

**Files Requiring Localization Fixes**:

**profile_page.dart**:
- Lines 416-417: "الملف الشخصي والإعدادات" → Localize
- Lines 461-462: "حسابك في BodyTalk AI" → Localize
- Lines 470-471: "إصدار تجريبي" → Localize
- Lines 487-496: "المعلومات الشخصية", "الاسم", etc → All localize
- Lines 555-586: "الجنس", "العمر التقريبي" → Localize
- All section titles, labels, and messages → Full localization

**body_analysis_page.dart**:
- Line 584-585: "الطول / العرض" → Localize to "Aspect Ratio" / "Ratio H/L" / "الطول / العرض"
- Line 650: "نصيحة من الذكاء الاصطناعي" → Localize
- All remaining hard-coded strings → Localize

**food_analysis_page.dart**:
- All nutritional labels (Calories, Protein, Carbs, Fat)
- Cuisine selector options
- AI advice section
- All hard-coded strings → Full localization

**Systematic Localization Process**:

1. Identify all hard-coded strings in each file
2. Replace with BodyTalkApp.tr() calls
3. Provide translations for all three languages
4. Test each page in all three languages
5. Verify RTL layout for Arabic
6. Ensure no layout overflow issues

**Language Code Management**:
- Stored in SharedPreferences as 'app_language'
- Values: 'en', 'fr', 'ar'
- Changed via Profile page language selector
- Immediately applied via BodyTalkApp.setLocaleStatic()

**Testing Requirements**:
- Test every page in English
- Test every page in French
- Test every page in Arabic
- Verify RTL text direction for Arabic
- Check for layout overflow in all languages
- Verify language persistence after app restart
- Test language switching without app restart

---

#### 2.2 Backend Localization for AI Responses
**Current Problem**: AI advice shows reversed language (English when Arabic selected, vice versa)

**Root Cause**: Backend returns fixed English advice regardless of user's language preference

**Solution Architecture**:

**Frontend to Backend Language Communication**:

**API Request Enhancement**:
- Add language parameter to analysis requests
- Send current user's language code with every analysis call
- Values: "en", "fr", "ar"

**Body Analysis Request** (`/analysis/body`):
- Current: Only sends image file
- Required: Add form field "language": "en"/"fr"/"ar"
- Backend receives language preference
- Returns localized advice text

**Food Analysis Request** (`/analysis/food`):
- Current: Only sends image file
- Required: Add form field "language": "en"/"fr"/"ar"
- Backend receives language preference
- Returns localized meal names and advice

**Frontend Implementation**:

**ApiService Enhancement**:
```
Modify analyzeBodyImage():
- Get current locale from BodyTalkApp state
- Add language field to multipart request
- Send as form field alongside image

Modify analyzeFoodImage():
- Same language field addition
- Ensure cuisine selector also sends language
```

**Backend Implementation** (`main.py`):

**Body Analysis Endpoint** (line 212-298):
- Accept optional language parameter (default: "en")
- Based on language, return localized advice:

**Advice Localization Strategy**:
```
if language == "ar":
    advice = "نصيحة بالعربية..."
elif language == "fr":
    advice = "Conseil en français..."
else:
    advice = "Advice in English..."
```

**Shape Classification Localization**:
- Body shape names: "Very Athletic" / "Très athlétique" / "رياضي جداً"
- Return localized shape name based on language parameter

**Food Analysis Endpoint** (line 304-395):
- Accept language parameter
- Return localized meal names:
  - "High-calorie meal" / "Repas riche en calories" / "وجبة عالية السعرات"
- Return localized advice in user's language
- Localize nutritional labels if needed

**Advice Templates by Language**:

**Body Analysis Advice Templates**:
- Athletic shape:
  - EN: "Your body shows good athletic levels..."
  - FR: "Votre corps montre de bons niveaux athlétiques..."
  - AR: "جسمك يظهر مستويات رياضية جيدة..."
- Balanced shape:
  - EN: "Your body proportions are approximately balanced..."
  - FR: "Les proportions de votre corps sont équilibrées..."
  - AR: "نسب جسمك متوازنة تقريباً..."
- High fat shape:
  - EN: "Indicators suggest a relatively high fat percentage..."
  - FR: "Les indicateurs suggèrent un pourcentage de graisse élevé..."
  - AR: "تشير المؤشرات إلى نسبة دهون مرتفعة نسبياً..."

**Food Analysis Advice Templates**:
- High calorie:
  - EN: "This looks like a quick, calorie-rich meal..."
  - FR: "Cela ressemble à un repas rapide et riche en calories..."
  - AR: "هذه تبدو وجبة سريعة وغنية بالسعرات..."
- Light meal:
  - EN: "This meal looks relatively light..."
  - FR: "Ce repas semble relativement léger..."
  - AR: "هذه الوجبة تبدو خفيفة نسبياً..."

**Testing Requirements**:
- Set app language to English → Analyze body → Verify English advice
- Set app language to French → Analyze body → Verify French advice
- Set app language to Arabic → Analyze body → Verify Arabic advice
- Same tests for food analysis
- Verify shape names localized correctly
- Verify meal names localized correctly
- Test with all three languages on physical device

---

#### 2.3 Cuisine Selector Re-enablement
**Current Status**: Cuisine selector mentioned in project plan but not visible in food analysis page

**Required Implementation**:

**Frontend (food_analysis_page.dart)**:

**UI Placement**:
- Add cuisine selector before image picker
- Position: Top section of food analysis page
- Design: Horizontal scrollable chip selector
- Default selection: Based on user's language preference

**Cuisine Options**:
- Arabic / Middle Eastern (عربي)
- Italian (إيطالي / Italien)
- Asian (آسيوي / Asiatique)
- American (أمريكي / Américain)
- French (فرنسي / Français)
- Mediterranean (متوسطي / Méditerranéen)
- Indian (هندي / Indien)
- Mexican (مكسيكي / Mexicain)
- International (عالمي / International)

**Cuisine Selector Design**:
```
Horizontal ListView with selectable chips:
- Selected chip: Orange background
- Unselected chip: Transparent with white border
- Icon + Text for each cuisine
- Localized cuisine names using BodyTalkApp.tr()
```

**Integration with Analysis**:

**Food Analysis API Enhancement**:
- Add cuisine parameter to /analysis/food request
- Backend uses cuisine context to improve recognition
- Return cuisine-specific nutritional profiles
- Adjust calorie estimates based on cuisine cooking methods

**Cuisine-Aware Analysis**:
- Arabic cuisine: Higher fat estimates for fried foods, rice dishes
- Italian: Pasta portion size considerations
- Asian: Rice-based meals, lighter cooking methods
- American: Larger portion sizes, higher calorie density

**Localized Cuisine Names**:
```
BodyTalkApp.tr(
  context,
  en: 'Arabic',
  fr: 'Arabe',
  ar: 'عربي',
)
```

**State Management**:
- Store selected cuisine in component state
- Default to user's cultural preference based on language
- Persist selection during session
- Send with image to backend

**Backend Integration** (`/analysis/food`):
- Accept cuisine parameter (optional, default: "international")
- Use cuisine context for meal name suggestion
- Apply cuisine-specific nutritional adjustments
- Return culturally appropriate advice

**Testing Requirements**:
- Test cuisine selector appears on food analysis page
- Test all cuisine options selectable
- Test cuisine names localized in all languages
- Test cuisine parameter sent to backend
- Verify cuisine-aware analysis results
- Test on physical device with different languages

---

### Phase 3: Subscription System Re-enablement (Critical)

#### 3.1 Subscription Status Visibility

**Current Problem**: Subscription system exists in backend but not visible in current app version

**Root Cause**: Profile page doesn't display subscription information

**Required Implementation**:

**Profile Page Enhancement**:

**Subscription Status Section**:
- Add dedicated subscription section in profile page
- Position: After personal information, before account management
- Icon: Crown icon for premium status
- Display:
  - Current plan (Free / Trial / Premium)
  - Status indicator (Active / Inactive)
  - Plan details if premium

**UI Design**:
```
Section Card:
- Title: "Subscription & Premium Features"
- Status Badge:
  - Free: Gray badge "Free Plan"
  - Trial: Orange badge "Trial Active"
  - Premium: Gold gradient badge "Premium Member"
- Benefits list based on plan
- Upgrade button if not premium
```

**API Integration**:

**On Profile Page Load**:
1. Call ApiService.getSubscriptionStatus()
2. Display subscription data:
   - is_active: Boolean
   - plan: String ("free", "trial", "premium")
   - provider: String ("test", "apple", "google")
3. Show appropriate UI based on status

**Subscription States**:

**Free User**:
- Badge: "Free Plan"
- Color: Gray
- Message: "Upgrade to unlock premium features"
- Button: "Upgrade to Premium"
- Limited features notification

**Trial User**:
- Badge: "Trial Active"
- Color: Orange
- Message: "You're currently on a trial subscription"
- Button: "Continue to Premium"
- Trial expiration date (if available)

**Premium User**:
- Badge: "Premium Member"
- Color: Gold gradient
- Message: "You have full access to all features"
- Provider display: "via Apple" / "via Google" / "Test Mode"
- Button: "Manage Subscription"

**Feature Access Control**:

**Analysis Limitations**:
- Free users:
  - Limited to 3 analyses per day
  - No history access beyond 7 days
  - Basic AI advice only
- Premium users:
  - Unlimited analyses
  - Full history access
  - Detailed AI advice
  - Priority processing

**Implementation Pattern**:
```
Before analysis:
1. Check subscription status
2. If free and limit reached:
   - Show upgrade dialog
   - Block analysis
3. If premium or within limits:
   - Proceed with analysis
```

**Test Subscription Activation**:

**Temporary Solution** (until payment integration):
- Keep existing "/subscriptions/activate-test" endpoint
- Add "Activate Test Premium" button in profile (dev mode only)
- Allow testing premium features
- Clear indication this is test mode

**Settings Menu Integration**:

**Subscription Management**:
- View current plan
- Upgrade/downgrade options
- Billing history (future)
- Cancel subscription (future)

**Localization**:

All subscription-related text localized:
- "Subscription" / "Abonnement" / "الاشتراك"
- "Free Plan" / "Plan gratuit" / "الخطة المجانية"
- "Premium Member" / "Membre premium" / "عضو مميز"
- "Upgrade" / "Mettre à niveau" / "الترقية"

**Error Handling**:
- Network failure: Show cached status if available
- API error: Assume free tier for safety
- Missing data: Default to free plan

**Testing Requirements**:
- Test subscription status display on profile page
- Test with no subscription (default free)
- Test with test subscription activated
- Test subscription check before analysis
- Test upgrade flow visibility
- Test in all three languages
- Verify on physical device

---

#### 3.2 Feature Gating Based on Subscription

**Objective**: Implement access control for premium features

**Feature Tiers**:

**Free Tier**:
- 3 body analyses per day
- 3 food analyses per day
- 7-day history access
- Basic AI advice
- Standard processing speed

**Premium Tier**:
- Unlimited body analyses
- Unlimited food analyses
- Unlimited history access
- Detailed AI advice with recommendations
- Priority processing
- Workout plan generation
- Meal plan generation
- Progress tracking charts
- Export analysis data

**Implementation Strategy**:

**Usage Tracking**:
- Store analysis count in local state
- Reset daily at midnight
- Check before allowing new analysis
- Server-side validation for accuracy

**Frontend Checks**:

**Before Body Analysis**:
1. Get subscription status
2. If free:
   - Check today's analysis count
   - If >= 3: Show upgrade dialog
   - Else: Proceed
3. If premium: Proceed without limits

**Before Food Analysis**:
- Same logic as body analysis
- Separate counter

**Before Accessing History**:
1. Get subscription status
2. If free:
   - Filter history to last 7 days only
   - Show "Upgrade for full history" banner
3. If premium:
   - Show all history

**Upgrade Prompts**:

**Limit Reached Dialog**:
- Title: "Daily limit reached"
- Message: "You've used all 3 free analyses today. Upgrade to Premium for unlimited access."
- Buttons:
  - "Upgrade Now" (navigate to subscription page)
  - "Maybe Later" (dismiss)
- Design: Eye-catching gradient background

**History Limit Banner**:
- Position: Top of history page
- Message: "Showing last 7 days. Upgrade to see full history"
- Action: Tap to view upgrade options

**Backend Validation**:

**Analysis Endpoints**:
- Check user's subscription status
- If free and limit exceeded: Return 429 (Too Many Requests)
- If premium: Process without limits
- Return appropriate error message

**Testing Requirements**:
- Test free user reaching analysis limit
- Test premium user unlimited access
- Test history filtering for free users
- Test upgrade prompts appearance
- Test subscription upgrade flow
- Verify server-side validation
- Test on physical device

---

## Implementation Priority

### Immediate (Week 1-2):
1. **Localization fixes** → Critical user experience issue
   - Fix all hard-coded strings in profile_page.dart
   - Fix body_analysis_page.dart localization
   - Fix food_analysis_page.dart localization
   - Implement backend language parameter
   - Test all three languages thoroughly

2. **Subscription visibility** → Core feature missing
   - Add subscription section to profile page
   - Display subscription status
   - Implement feature gating
   - Test subscription flow

### High Priority (Week 3-4):
3. **Google Sign-In** → Major auth feature
   - Add Google button to login page
   - Implement complete auth flow
   - Test on physical devices

4. **Biometric authentication improvements** → UX enhancement
   - Implement enable/disable toggle
   - Add auto-prompt on app open
   - Improve user flow clarity
   - Test on iOS and Android

### Medium Priority (Week 5-6):
5. **Apple Sign-In** → iOS-specific feature
   - Add Apple button (iOS/macOS only)
   - Implement auth flow
   - Handle privacy requirements
   - Test on iPhone

6. **Password reset completion** → Account recovery
   - Implement token generation
   - Set up email service
   - Create reset confirmation endpoint
   - Test complete flow

7. **Cuisine selector** → Food analysis enhancement
   - Add UI selector
   - Integrate with backend
   - Localize cuisine names
   - Test cuisine-aware analysis

---

## Technical Implementation Details

### Frontend Changes Required

**Files to Modify**:

1. **lib/pages/login_page.dart**
   - Add Google Sign-In button (after line 667)
   - Add Apple Sign-In button (iOS/macOS only)
   - Keep existing password reset dialog functional
   - Improve biometric button visibility logic

2. **lib/pages/profile_page.dart**
   - Replace ALL hard-coded Arabic strings with BodyTalkApp.tr()
   - Add subscription status section
   - Add subscription management options
   - Localize all text elements
   - Add biometric toggle in settings

3. **lib/pages/body_analysis_page.dart**
   - Localize remaining hard-coded strings
   - Send language parameter to backend
   - Display localized AI advice
   - Localize all labels and titles

4. **lib/pages/food_analysis_page.dart**
   - Add cuisine selector UI
   - Localize all nutritional labels
   - Send language and cuisine parameters to backend
   - Display localized AI advice
   - Localize meal names

5. **lib/services/api_service.dart**
   - Modify analyzeBodyImage() to accept language parameter
   - Modify analyzeFoodImage() to accept language and cuisine parameters
   - Ensure subscription endpoints properly called

6. **lib/main.dart**
   - Add static method to get current locale code
   - Ensure BodyTalkApp.tr() accessible from all contexts

### Backend Changes Required

**Files to Modify**:

1. **bodytalk_server/main.py**
   
   **Body Analysis Endpoint** (line 212):
   - Accept optional `language` form field
   - Implement advice localization logic
   - Return localized shape names
   - Return localized advice text
   
   **Food Analysis Endpoint** (line 304):
   - Accept optional `language` form field
   - Accept optional `cuisine` form field
   - Implement meal name localization
   - Implement advice localization
   - Apply cuisine-specific adjustments
   
   **Social Login Endpoint** (new):
   - Implement `/auth/social-login` endpoint
   - Validate Google tokens
   - Validate Apple tokens
   - Create/retrieve user accounts
   - Return JWT access tokens
   
   **Password Reset Enhancement** (line 152):
   - Generate secure reset tokens
   - Implement email sending
   - Add `/auth/reset-password` confirmation endpoint
   - Validate tokens and update passwords

2. **bodytalk_server/auth_utils.py**
   - Add Google token validation function
   - Add Apple token validation function
   - Add password reset token generation
   - Add token validation utilities

3. **bodytalk_server/models.py**
   - Add password reset token field to User model (optional)
   - Track social provider in User model

---

## Quality Assurance Checklist

### Testing Requirements

**Authentication Testing**:
- [ ] Password reset flow works end-to-end
- [ ] Email sent and received
- [ ] Reset token validates correctly
- [ ] Password successfully updated
- [ ] Google Sign-In button visible
- [ ] Google Sign-In authenticates successfully
- [ ] Google account selection works
- [ ] Apple Sign-In button visible on iOS only
- [ ] Apple Sign-In authenticates on iPhone
- [ ] Apple Sign-In hidden on Android
- [ ] Biometric prompt appears automatically on app open
- [ ] Biometric toggle works in settings
- [ ] Biometric login succeeds with valid token
- [ ] Biometric failure shows appropriate error

**Localization Testing**:
- [ ] All profile page texts appear in selected language
- [ ] Body analysis page fully localized
- [ ] Food analysis page fully localized
- [ ] AI advice appears in correct language
- [ ] Body shape names localized
- [ ] Meal names localized
- [ ] Nutritional labels localized
- [ ] No hard-coded Arabic strings in English mode
- [ ] No hard-coded English strings in Arabic mode
- [ ] RTL layout correct for Arabic
- [ ] No layout overflow in any language
- [ ] Language change applies immediately
- [ ] Language persists after app restart

**Subscription Testing**:
- [ ] Subscription status visible in profile
- [ ] Free plan badge displays correctly
- [ ] Premium badge displays correctly
- [ ] Test subscription activation works
- [ ] Feature limits enforced for free users
- [ ] Upgrade prompts appear when limit reached
- [ ] Premium users have unlimited access
- [ ] History filtering works for free users
- [ ] Subscription status localized in all languages

**Cuisine Selector Testing**:
- [ ] Cuisine selector visible on food analysis page
- [ ] All cuisine options selectable
- [ ] Cuisine names localized in all languages
- [ ] Cuisine parameter sent to backend
- [ ] Analysis results reflect cuisine selection

**Physical Device Testing**:
- [ ] All features tested on Android phone
- [ ] All features tested on iPhone
- [ ] Google Sign-In works on both platforms
- [ ] Apple Sign-In works on iPhone
- [ ] Biometric authentication works on both
- [ ] All languages tested on physical devices
- [ ] No crashes or UI issues
- [ ] Performance acceptable

---

## Success Criteria

### Authentication System
1. Users can reset password via email
2. Users can sign in with Google on all platforms
3. Users can sign in with Apple on iOS/macOS
4. Biometric login works smoothly with clear enable/disable option
5. All authentication methods tested and functional on physical devices

### Localization
1. Switching to English shows ALL texts in English
2. Switching to French shows ALL texts in French
3. Switching to Arabic shows ALL texts in Arabic
4. AI advice appears in user's selected language
5. Body analysis results fully localized
6. Food analysis results fully localized
7. No hard-coded strings remain in any page
8. RTL layout works correctly for Arabic
9. No layout overflow issues in any language

### Subscription System
1. Subscription status visible in profile page
2. Free/Premium/Trial status clearly displayed
3. Feature limits enforced for free users
4. Premium users have unlimited access
5. Upgrade prompts appear appropriately
6. Subscription information localized
7. Test subscription activation works

### General
1. All fixes verified on physical Android device
2. All fixes verified on physical iPhone (where applicable)
3. No crashes or major bugs introduced
4. User experience significantly improved
5. All features working as expected in actual application

---

## Development Workflow

### Step-by-Step Implementation

**Phase 1: Localization (Priority 1)**
1. Create localization audit document listing all hard-coded strings
2. Implement BodyTalkApp.tr() for all profile page strings
3. Implement BodyTalkApp.tr() for body analysis page
4. Implement BodyTalkApp.tr() for food analysis page
5. Add language parameter to backend endpoints
6. Implement backend advice localization
7. Test all three languages on each page
8. Fix any layout overflow issues
9. Deploy and test on physical device

**Phase 2: Subscription (Priority 2)**
1. Design subscription status UI for profile page
2. Implement subscription section in profile
3. Integrate API calls for subscription status
4. Implement feature gating logic
5. Add upgrade prompts
6. Localize all subscription texts
7. Test free vs premium flows
8. Deploy and test on physical device

**Phase 3: Google Sign-In (Priority 3)**
1. Design Google button for login page
2. Implement button UI with proper styling
3. Integrate SocialAuthService.signInWithGoogle()
4. Implement backend social login endpoint
5. Add Google token validation
6. Test authentication flow
7. Handle error cases
8. Deploy and test on Android and iOS devices

**Phase 4: Biometric Enhancement (Priority 4)**
1. Add biometric enable/disable preference storage
2. Implement auto-prompt on app open
3. Add settings toggle in profile
4. Improve error messaging
5. Test on iOS (Face ID) and Android (Fingerprint)
6. Deploy and test on physical devices

**Phase 5: Apple Sign-In (Priority 5)**
1. Design Apple button for login page (iOS/macOS only)
2. Implement platform detection
3. Integrate SocialAuthService.signInWithApple()
4. Implement backend Apple token validation
5. Test on iPhone
6. Verify hidden on Android
7. Deploy and test on iOS device

**Phase 6: Password Reset & Cuisine (Priority 6-7)**
1. Set up email service (SendGrid/AWS SES)
2. Implement reset token generation
3. Create reset confirmation endpoint
4. Test complete password reset flow
5. Design cuisine selector UI
6. Implement cuisine selection logic
7. Integrate with backend
8. Test cuisine-aware analysis

---

## Risk Mitigation

### Potential Issues

**Localization**:
- Risk: Missing translations causing app crashes
- Mitigation: Default to English if translation missing
- Risk: Layout overflow with longer translations
- Mitigation: Use flexible layouts, test all languages

**Authentication**:
- Risk: Social auth token validation failures
- Mitigation: Comprehensive error handling and fallback
- Risk: Biometric hardware not available
- Mitigation: Check availability before showing option

**Subscription**:
- Risk: Backend API failures affecting feature access
- Mitigation: Cache subscription status, fail-safe to free tier
- Risk: Subscription status sync issues
- Mitigation: Periodic background refresh

**General**:
- Risk: Changes breaking existing functionality
- Mitigation: Comprehensive testing before each deployment
- Risk: Performance degradation
- Mitigation: Profile and optimize critical paths

---

## Deployment Strategy

### Staged Rollout

**Stage 1: Localization Fix**
- Deploy backend language parameter support
- Deploy frontend localization fixes
- Test thoroughly on physical devices
- Verify no regressions
- Monitor for issues

**Stage 2: Subscription Visibility**
- Deploy subscription UI changes
- Deploy feature gating logic
- Test premium vs free flows
- Monitor subscription status calls

**Stage 3: Authentication Enhancements**
- Deploy Google Sign-In (all platforms)
- Deploy biometric improvements
- Deploy Apple Sign-In (iOS only)
- Test on physical devices
- Monitor authentication success rates

**Stage 4: Additional Features**
- Deploy password reset enhancements
- Deploy cuisine selector
- Final comprehensive testing
- Production release

### Rollback Plan

- Maintain previous working APK/IPA builds
- Document all changes for easy reversal
- Have backend feature flags for new endpoints
- Quick rollback procedure if critical issues found

---

## Documentation Requirements

### Code Documentation
- Comment all localization changes
- Document subscription logic
- Explain authentication flows
- Add inline comments for complex logic

### User Documentation
- Update app help section
- Create subscription comparison table
- Document authentication options
- Add language switching guide

### Developer Documentation
- Update README with new features
- Document API changes
- Create localization guide
- Update testing procedures
