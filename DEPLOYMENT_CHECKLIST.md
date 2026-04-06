# ✅ DEPLOYMENT CHECKLIST - Veroprise ERP v2.0

## 📋 PRE-DEPLOYMENT

### 1. Environment Setup
- [ ] Supabase project created (new/clean)
- [ ] Get project URL & anon key
- [ ] Update `.env` file with credentials
- [ ] Git repository setup & committed

### 2. Database Preparation
- [ ] Backup any existing data (if applicable)
- [ ] Review all migration files
- [ ] Check RLS policies are correct
- [ ] Test migrations in local/staging first

### 3. Frontend Preparation
- [ ] All dependencies installed (`bun install`)
- [ ] TypeScript compilation success (`bun run build`)
- [ ] No console errors in development
- [ ] Review all component imports

---

## 🗄️ DATABASE DEPLOYMENT

### Step 1: Connect to Supabase
```bash
supabase link --project-ref YOUR_PROJECT_REF
```
- [ ] Connection successful
- [ ] Project linked correctly

### Step 2: Run Base Migrations (If New Project)
```bash
# Run existing migrations first
supabase db push
```
- [ ] All base tables created
- [ ] Users, outlets, products, etc exist
- [ ] No migration errors

### Step 3: Run New Feature Migrations
```bash
# Warehouse system
supabase db push supabase/migrations/20260117_warehouse_system.sql

# Multi-payment system  
supabase db push supabase/migrations/20260117_multi_payment_system.sql

# HR system
supabase db push supabase/migrations/20260117_hr_attendance_incentives.sql
```
- [ ] Warehouse tables created (9 tables)
- [ ] Transaction_payments table created
- [ ] HR tables created (4 tables)
- [ ] All triggers installed
- [ ] All functions installed
- [ ] All RLS policies active

### Step 4: Verify Database
```sql
-- Check tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
  'warehouses',
  'warehouse_inventory',
  'purchase_orders',
  'stock_transfer_orders',
  'transaction_payments',
  'attendance',
  'sales_targets',
  'employee_incentives'
);

-- Should return 8 rows
```
- [ ] All 8 tables exist
- [ ] No permission errors
- [ ] Sample data can be inserted

### Step 5: Test Database Functions
```sql
-- Test payment status trigger
INSERT INTO transactions (outlet_id, user_id, total_amount, payment_status)
VALUES ('outlet-id', 'user-id', 100000, 'pending');

INSERT INTO transaction_payments (transaction_id, payment_method, amount)
VALUES ('transaction-id', 'cash', 50000);

-- Check if payment_status updated to 'partial'
SELECT payment_status FROM transactions WHERE id = 'transaction-id';
-- Should return 'partial'
```
- [ ] Trigger works correctly
- [ ] Status updated automatically

---

## 🎨 FRONTEND DEPLOYMENT

### Step 1: Build Production
```bash
cd barberdoc_erp
bun run build
```
- [ ] Build successful
- [ ] No TypeScript errors
- [ ] No build warnings (critical ones)
- [ ] Dist folder generated

### Step 2: Deploy to Netlify
```bash
netlify deploy --prod
```
OR
```bash
# For Vercel
vercel --prod
```
- [ ] Deployment successful
- [ ] Site URL accessible
- [ ] No 404 errors on routes
- [ ] Environment variables set correctly

### Step 3: Verify Frontend
- [ ] App loads without errors
- [ ] Supabase connection works
- [ ] Login/authentication works
- [ ] All pages accessible

---

## 🧪 FUNCTIONAL TESTING

### 1. Multi-Payment System
- [ ] **Test Case 1: Single Payment**
  - Add items to cart (Total: Rp 50.000)
  - Select Cash Rp 50.000
  - Confirm payment
  - Check transaction created with status 'paid'
  - Check 1 record in transaction_payments

- [ ] **Test Case 2: DP + Pelunasan**
  - Add items (Total: Rp 100.000)
  - Payment #1: Transfer Rp 40.000 (ref: TRF-123)
  - Payment #2: Cash Rp 60.000
  - Confirm payment
  - Check 2 records in transaction_payments
  - Check status = 'paid'

- [ ] **Test Case 3: Partial Payment**
  - Add items (Total: Rp 150.000)
  - Payment #1: QRIS Rp 50.000
  - Warning appears: "Kekurangan Rp 100.000"
  - Confirm anyway
  - Check status = 'partial'

### 2. Warehouse System
- [ ] **Test Case 4: Create Warehouse**
  - Navigate to Warehouse menu
  - Click "Tambah Gudang"
  - Fill form (name, address, manager)
  - Submit
  - Check warehouse appears in list

- [ ] **Test Case 5: Purchase Order**
  - Navigate to PO menu
  - Create new PO
  - Select warehouse & supplier
  - Add 3 items
  - Submit PO
  - Check PO status = 'submitted'

- [ ] **Test Case 6: Stock Transfer**
  - Navigate to Stock Transfer
  - Select warehouse & outlet
  - Add 2 items
  - Check stock availability displayed
  - Submit request
  - Check status = 'pending'

- [ ] **Test Case 7: Stock Opname**
  - Navigate to Stock Opname
  - Select warehouse
  - Load inventory
  - Change physical qty for 2 products
  - Check difference calculated automatically
  - Save opname

- [ ] **Test Case 8: Daily Closing**
  - Navigate to Daily Closing
  - Select outlet & date
  - Check sales by method loaded
  - Check cash deposit calculated correctly
  - Formula: Cash Sales - Expenses
  - Submit report

### 3. HR System
- [ ] **Test Case 9: Auto-Attendance**
  - Create shift assignment for today
  - Check attendance record created automatically
  - Status should be 'pending'
  - Clock in from attendance dashboard
  - Check clock_in timestamp recorded
  - Clock out
  - Check clock_out timestamp recorded

- [ ] **Test Case 10: Sales Target**
  - Navigate to Sales Target
  - Create new target (product-based, daily)
  - Set target amount & incentive
  - Save target
  - Check target appears in list
  - Make sales that meet target
  - Check incentive auto-generated

- [ ] **Test Case 11: Incentive Approval**
  - Navigate to Incentive Dashboard
  - Check pending incentives
  - Click "Approve" on one incentive
  - Check status changed to 'approved'
  - Verify amount correct

---

## 👥 USER ACCEPTANCE TESTING (UAT)

### Test with Real Users
- [ ] Owner/Manager login
  - Can view all outlets
  - Can approve POs
  - Can approve incentives
  - Can view reports

- [ ] Admin login
  - Can create POs
  - Can create stock transfers
  - Can manage attendance
  - Can process payments

- [ ] Cashier login
  - Can access POS
  - Can process multi-payment
  - Can view daily sales
  - Cannot access admin features

- [ ] Employee login
  - Can clock in/out
  - Can view own attendance
  - Can view own incentives
  - Cannot access other employee data

---

## 📊 PERFORMANCE TESTING

### Database Performance
- [ ] Query response time < 500ms
- [ ] Bulk insert 100 records < 2 seconds
- [ ] Report generation < 3 seconds
- [ ] No N+1 query issues

### Frontend Performance
- [ ] Page load time < 2 seconds
- [ ] Lighthouse score > 80
- [ ] Mobile responsive
- [ ] No memory leaks

---

## 🔒 SECURITY CHECKLIST

### Database Security
- [ ] RLS policies enabled on all tables
- [ ] Users can only access their outlet data
- [ ] Admin can access all outlets
- [ ] Sensitive data encrypted
- [ ] SQL injection prevented (using prepared statements)

### Frontend Security
- [ ] API keys not exposed in frontend
- [ ] CORS configured correctly
- [ ] Authentication required for all routes
- [ ] Role-based access control (RBAC) working
- [ ] Input validation on all forms

### Network Security
- [ ] HTTPS enabled
- [ ] Secure cookies
- [ ] Rate limiting configured
- [ ] DDoS protection (Netlify/Vercel default)

---

## 📖 DOCUMENTATION

### For Developers
- [ ] README.md updated
- [ ] API documentation complete
- [ ] Database schema documented
- [ ] Deployment guide available
- [ ] Troubleshooting guide available

### For Users
- [ ] User manual created (or use QUICK_REFERENCE.md)
- [ ] Video tutorials (optional)
- [ ] FAQ document
- [ ] Support contact info

---

## 🎓 TRAINING

### Staff Training
- [ ] Training materials prepared
- [ ] Training schedule set
- [ ] All staff members trained:
  - [ ] Owner/Manager
  - [ ] Admin
  - [ ] Cashiers
  - [ ] Employees

### Training Topics Covered
- [ ] Multi-payment usage
- [ ] Warehouse management flow
- [ ] Stock opname procedure
- [ ] Daily closing report
- [ ] Attendance clock in/out
- [ ] Sales target & incentive system

---

## 🚀 GO-LIVE

### Final Checks
- [ ] All testing completed
- [ ] All critical bugs fixed
- [ ] Backup plan ready
- [ ] Rollback plan ready
- [ ] Support team standby
- [ ] Monitoring enabled

### Launch Day
- [ ] Announce go-live to all users
- [ ] Monitor system for first 24 hours
- [ ] Quick response to any issues
- [ ] Collect initial feedback

### Post-Launch (Week 1)
- [ ] Daily check-ins with users
- [ ] Monitor error logs
- [ ] Fix any reported bugs
- [ ] Gather improvement suggestions

---

## 📞 SUPPORT PLAN

### Level 1 Support (Users)
- **Channel:** WhatsApp group
- **Response Time:** < 1 hour
- **Coverage:** 8am - 8pm daily

### Level 2 Support (Technical)
- **Channel:** Email + Telegram
- **Response Time:** < 4 hours
- **Coverage:** On-call 24/7

### Level 3 Support (Developer)
- **Channel:** Direct call
- **Response Time:** < 24 hours
- **Coverage:** Critical issues only

---

## 🎯 SUCCESS METRICS

### Week 1 Goals
- [ ] 100% user adoption
- [ ] < 5 critical bugs
- [ ] System uptime > 99%
- [ ] User satisfaction > 80%

### Month 1 Goals
- [ ] All features actively used
- [ ] No critical bugs
- [ ] System uptime > 99.5%
- [ ] User satisfaction > 90%

### Quarter 1 Goals
- [ ] ROI positive
- [ ] Time saved: 20+ hours/week
- [ ] Revenue increase: 10-15%
- [ ] Feature adoption > 95%

---

## ✅ SIGN-OFF

### Development Team
- [ ] Lead Developer: ________________ Date: _______
- [ ] QA Engineer: ________________ Date: _______
- [ ] DevOps: ________________ Date: _______

### Client Team
- [ ] Owner: ________________ Date: _______
- [ ] Manager: ________________ Date: _______
- [ ] Admin: ________________ Date: _______

### Final Approval
- [ ] Client accepts delivery
- [ ] Payment processed
- [ ] Handover complete
- [ ] Support contract signed

---

## 🎉 CONGRATULATIONS!

**Veroprise ERP v2.0 is now LIVE!** 🚀

Thank you for using our system. We're here to support your business growth!

---

**Support Contacts:**
- 📱 WhatsApp: 08XX-XXXX-XXXX
- 💬 Telegram: @veroprise_support
- 📧 Email: support@veroprise.com
- 🌐 Website: veroprise.com

---

*Checklist version: 2.0*
*Last updated: January 18, 2026*
