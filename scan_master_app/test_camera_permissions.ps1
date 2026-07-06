$adb = "C:\Users\NITESH\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$pkg = "com.scanmaster.scan_master_app"

Write-Host "Clearing logcat..."
& $adb logcat -c

Write-Host "Test 1: Revoke Permission"
& $adb shell pm revoke $pkg android.permission.CAMERA
Start-Sleep -Seconds 1

Write-Host "Launching App..."
& $adb shell am start -n "$pkg/$pkg.MainActivity"
Start-Sleep -Seconds 4

Write-Host "Tapping Scan (Center FAB)..."
& $adb shell input tap 540 2250
Start-Sleep -Seconds 2

Write-Host "Fetching logcat for Denied scenario..."
& $adb logcat -d > logcat_denied.txt

Write-Host "Test 2: Grant Permission"
& $adb shell pm grant $pkg android.permission.CAMERA
Start-Sleep -Seconds 1

Write-Host "Tapping Scan (Center FAB)..."
& $adb shell input tap 540 2250
Start-Sleep -Seconds 3

Write-Host "Fetching logcat for Granted scenario..."
& $adb logcat -d > logcat_granted.txt

Write-Host "Done!"
