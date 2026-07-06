$adb = "C:\Users\NITESH\AppData\Local\Android\Sdk\platform-tools\adb.exe"

Write-Host "Launching App..."
& $adb shell am start -n com.scanmaster.scan_master_app/com.scanmaster.scan_master_app.MainActivity
Start-Sleep -Seconds 5

Write-Host "Test 1: Revoke Camera Permission"
& $adb shell pm revoke com.scanmaster.scan_master_app android.permission.CAMERA
Start-Sleep -Seconds 1

Write-Host "Relaunching App (since revoke kills it)..."
& $adb shell am start -n com.scanmaster.scan_master_app/com.scanmaster.scan_master_app.MainActivity
Start-Sleep -Seconds 4

Write-Host "Tapping Scan FAB to see Permission Denied message..."
& $adb shell input tap 900 2200
Start-Sleep -Seconds 4

Write-Host "Test 2: Granting Camera Permission (Simulating Settings Allow)..."
& $adb shell pm grant com.scanmaster.scan_master_app android.permission.CAMERA
Start-Sleep -Seconds 2

Write-Host "Tapping Scan FAB again to see Camera Open..."
& $adb shell input tap 900 2200
Start-Sleep -Seconds 5
Write-Host "Simulation Complete!"
