# 🏋️‍♂️ calendarWorkOutApp

A state-of-the-art **Workout Calendar & Tracker** iOS application built with **SwiftUI**. The app features a high-end **glassmorphic design**, real-time **weather metrics**, and an **AI-driven workout recommendation engine** that suggests perfect workouts (e.g. Indoor HIIT, Scenic Outdoor Run, Restorative Flow) based on live meteorological data!

---

## 🚀 Seamless VS Code & Xcode Sync Guide

Developing modern mobile applications can be done by combining the agility of **VS Code** with the native compilation features of **Xcode**. Here is how we configured your project to make this experience completely frictionless.

### 🔄 How Synchronization Works (Filesystem-Level Integration)
This project uses Xcode's modern **`PBXFileSystemSynchronizedRootGroup`** feature. 
Unlike older projects where files had to be manually dragged and added to the Xcode file explorer, **Xcode now synchronizes directly with your physical folder on disk.**

* **No Copy/Sync Script Required:** Any file or folder you create, edit, or delete inside the `calendarWorkOutApp` directory in **VS Code** will be **instantly and automatically** detected and updated inside **Xcode**.
* **Edit in VS Code, Run in Xcode:** You can keep VS Code open as your primary code editor, modify Swift files, hit save, and then simply build/test inside Xcode or via the command line.

---

## 🛠 VS Code Setup

To get a first-class Swift editing experience inside VS Code, we recommend:

1. **Install Extensions:**
   * **Swift** (by Apple) – provides code completion, formatting, and diagnostics.
   * **iOS Common Tasks** or **SwiftLint** (optional) – for syntax cleaning.
2. **Custom Tasks Included:**
   We have added a custom `.vscode/tasks.json` with three predefined automation tasks:
   * **`Build iOS App (Simulator)` (Cmd + Shift + B):** Compiles your app directly from your VS Code terminal using `xcodebuild`.
   * **`Run iOS Simulator`:** Automatically boots your active iOS simulator.
   * **`Install & Launch App in Simulator`:** Installs the newly compiled `.app` bundle onto your simulator and runs it.

---

## 📱 Testing Your App

### Method A: Using Xcode (Easiest & Recommended)
1. Open the project folder in Finder.
2. Double-click **`calendarWorkOutApp.xcodeproj`** to open the workspace in Xcode.
3. Select your target device (e.g. **iPhone 15 Pro** simulator) from the scheme selector at the top.
4. Press **`Cmd + R`** (or click the **Play** button) to build and run!

### Method B: Pure Terminal / VS Code Tasks
1. Press `Cmd + Shift + P` in VS Code.
2. Select **`Tasks: Run Task`** -> **`Run iOS Simulator`**.
3. Press **`Cmd + Shift + B`** to compile the project.
4. Run task **`Install & Launch App in Simulator`** to push it onto the simulator.

---

## 📲 Deploying to a Physical iOS Device

To test and log your workouts on your **physical iPhone or iPad**:

1. **Connect Your Device:** Connect your iPhone/iPad to your Mac using a USB cable.
2. **Select Device in Xcode:** In the top scheme selector in Xcode, choose your physical device instead of a simulator.
3. **Configure Code Signing:**
   * Go to the project settings in Xcode (click on the top-level folder icon named `calendarWorkOutApp` in the left sidebar).
   * Click on the **`Signing & Capabilities`** tab.
   * Check **`Automatically manage signing`**.
   * Under **`Team`**, select your Apple ID (Personal Team). Xcode will automatically register your provisioning profiles.
4. **Enable Developer Mode (on iOS 16+):**
   * On your iPhone, go to **Settings > Privacy & Security**.
   * Scroll down to **Developer Mode** and toggle it **On**.
   * Restart your device as prompted, and enter your passcode.
5. **Run the App:** Press **`Cmd + R`** in Xcode.
6. **Trust the Certificate:** On your iPhone, the first time you run, you'll see an "Untrusted Developer" popup.
   * Go to **Settings > General > VPN & Device Management**.
   * Under "Developer App", tap your Apple ID email.
   * Tap **Trust "[Your Email]"** and confirm.
   * Open the app and start logging your workouts!

---

## ⚙️ Mobile Device Compatibility Settings

The project has been fully pre-configured for modern, production-grade mobile compatibility:

* **iOS Target:** Built and configured for **iOS 17.0+** to leverage modern SwiftUI APIs (like `.safeAreaInset`, `.task`, and premium glassmorphic materials).
* **Supported Devices:** Universal build targeting **iPhone** and **iPad** form-factors with adaptive layouts.
* **Orientations:**
  * **iPhone:** Restricted to **Portrait** mode, which is the ergonomic standard for logging gym sets and checking metrics while on the move, but also supports landscape left/right if running on a dock.
  * **iPad:** Supports **all orientations** (Portrait, Landscape, Upside-down) to utilize split-screen layouts when displaying workout programs on gym stands.
* **Modern Layouts:** Employs high-end safe-area constraints ensuring zero overlap with the Dynamic Island, notch, or home indicator bar across all screen sizes.
