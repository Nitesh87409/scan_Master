# Planning Rules

1. **No Automatic Execution**:
   - Jab tak user explicitly "aage badho", "yes" ya "start karo" na kahe, tab tak implementation plan par auto-execute nahi karna hai. User ka manual confirmation mandatory hai.

2. **Brain.md Updation & Version Bump**:
   - Har task ya naye feature/update ke baad project ki root directory mein `brain.md` file ko update karna mandatory hai.
   - `brain.md` me ekdam detailed records hone chahiye ki aaj kya update kiya, kaunse events lagaye, kya states change kiye.
   - Uske sath hi `pubspec.yaml` me hamesha chota sa version bump (e.g. 1.0.0+1 to 1.0.1+2) karna mandatory hai.

3. **Mandatory Clean Before Install**:
   - Har baar device par nayi app install (flutter run ya build) karne se pehle `flutter clean` karna zaroori hai. Isse purana cache clear ho jayega aur hamesha fresh naya version hi install hoga.

4. **SEO & Dynamic Content (App Ranking)**:
   - Koi bhi text ya configuration hardcode nahi karni hai, sab kuch dynamic rakhna hai (jaise strings, labels wagaira) taaki future me modify karna aasan ho.
   - App ke features aur components banate waqt "App Store Optimization (ASO) / SEO friendly" mindset rakhna hai. Jo bhi feature banayein, unka naam aur structure aisa ho jo search ranking me madad kare.

5. **Explicitly Mention Rule Compliance**:
   - Code edit karne ke baad user ko response dete waqt clearly mention karna zaroori hai ki maine `AGENTS.md` ke saare rules (jaise version bump, brain.md update, SEO rules, etc.) ko follow karte hue changes kiye hain.
