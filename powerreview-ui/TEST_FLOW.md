# PowerReview Streamlined Pre-flight Test Flow

## Test Scenario: New Quick Start Flow

### 1. Login Page
- Navigate to `/login`
- Enter credentials:
  - Email: `admin@telana.com`
  - Password: `PowerReview2024!`
- Click "Sign In Securely"
- Should redirect to `/preflight-new`

### 2. New Pre-flight Page (`/preflight-new`)
You should see:
- **Two card options**:
  1. **Quick Start (Recommended)** - with "Sign in with Microsoft" button
  2. **Manual Setup** - with link to old checklist

- **PIM Notice** at the bottom

### 3. Quick Start Flow
1. Click "Sign in with Microsoft" button
2. A modal should appear showing:
   - "Signing you in to Microsoft 365"
   - Three progress steps:
     - ✓ Authenticating with Microsoft
     - ✓ Verifying Permissions
     - ✓ Configuring Assessment

3. After simulation completes, you should see:
   - Success message
   - Account details:
     - Email: admin@contoso.com
     - Tenant: contoso.onmicrosoft.com
     - Access Level: Global Administrator
   - "Continue to Assessment Selection" button

### 4. PIM Flow (if needed)
- Click "Learn about PIM activation" link
- Should navigate to `/preflight-pim`
- Features:
  - Tenant domain input field
  - "Auto-detect from Microsoft Sign-in" button
  - Pre-populated links based on tenant
  - 5-minute countdown timer
  - Step-by-step PIM activation guide

## Key Features to Test:

### Auto-Detection
1. The system should attempt to detect:
   - Signed-in Microsoft account from localStorage
   - MSAL tokens if present
   - Auto-populate tenant domain

### Dynamic Link Generation
1. On PIM page, enter a tenant domain (e.g., `contoso.onmicrosoft.com`)
2. Click "Update Links"
3. All links should update to include the tenant:
   - PIM activation: `https://portal.azure.com/contoso.onmicrosoft.com#blade/...`
   - Admin center: `https://admin.microsoft.com/?tenant=contoso.onmicrosoft.com`

### Visual Feedback
- Loading spinners during authentication
- Step completion indicators (✓)
- Success/error states
- Smooth animations and transitions

## Alternative Paths:

### Manual Setup
- Click "Use Manual Checklist"
- Should navigate to `/preflight-detailed`
- Traditional checklist still available

### Direct Navigation
- Users can still access:
  - `/preflight` - Original checklist
  - `/preflight-detailed` - Detailed verification guide
  - `/preflight-pim` - PIM activation guide

## Expected User Experience:
1. **Time to complete**: < 2 minutes (vs 10-15 minutes for manual)
2. **Clicks required**: 2-3 (vs 20+ checkboxes)
3. **Manual input**: None (vs multiple fields)
4. **Automatic verification**: All permissions checked
5. **Clear feedback**: Visual progress and results

## Integration Points:
- OAuth flow would connect to Microsoft Identity Platform
- Graph API would verify:
  - User roles and permissions
  - Tenant information
  - Available services
- Results stored in sessionStorage for assessment use