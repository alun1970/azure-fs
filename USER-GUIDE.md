# 🚀 Agave New Ventures File Share - User Guide

## 📋 What This Does
This gives you secure access to **Agave New Ventures** shared files through your Windows File Explorer. After setup, you'll see "Agave New Ventures Data" in your sidebar with a blue building icon.

## ⚡ Quick Setup (2 Minutes)

### Step 1: Installation (Done by IT)
Your IT administrator will install the file share software on your computer via:
- Microsoft Intune (automatic)
- Group Policy (automatic)  
- Or by sending you an installer file

### Step 2: Run the Setup  
1. Click **Start button** → Search for **"Setup File Share Access"**
2. Click on **"Setup File Share Access"**
3. Sign in when the browser opens (use your company email)
4. Wait for setup to complete (shows green success messages)

### Step 3: Access Your Files
1. Open **File Explorer** (Windows Key + E)
2. Look for **"Agave New Ventures Data"** in the left sidebar
3. Click on it to access your shared files

## ✅ That's It!
Your Azure File Share is now ready to use. No passwords needed - it works automatically!

---

## 🔧 If You Have Problems

### Problem: "Access Denied" or Login Prompts
**Solution:** Run "Setup File Share Access" again from the Start Menu

### Problem: Can't See "Agave New Ventures Data" in Sidebar
**Solution:** 
1. Close all File Explorer windows
2. Wait 30 seconds
3. Open File Explorer again
4. If still not there, restart your computer

### Problem: Setup Shows Errors
**Solution:** 
1. Try running "Test File Share Connection" from Start Menu first
2. Contact your IT administrator with the error message  
3. Provide the log file from: `%TEMP%\AgaveFileShare-Setup.log`
4. Include any error messages from the test results

---

## 📞 Need Help?
Contact: **Your IT Administrator**
- Include any error messages you see
- Mention you're setting up "Azure File Share access"

---

## 🔒 Security Notes
- This uses enterprise-grade Azure security
- Your credentials are stored securely by Windows
- No passwords are saved in plain text
- All access is logged and auditable