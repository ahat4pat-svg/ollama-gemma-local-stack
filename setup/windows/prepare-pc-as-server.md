# Prepare your 16 GB PC as a dedicated AI server

Before installing Ollama + Gemma, prep the machine. The goal :
- **Free up disk space** (Gemma 4 MoE alone is ~26 GB; you want 60+ GB free for models + workspace)
- **Free up RAM** by killing unnecessary background stuff (you only have 16 GB)
- **Stop the machine from sleeping** when no one is at the keyboard
- **Move large data to external storage** so the SSD stays lean

You don't have to do every step. Pick what applies to your situation.

---

## 1. Disk cleanup — free up space

### 1.1 Built-in disk cleanup
```powershell
# Run as Administrator
cleanmgr /sageset:1
# UI opens — check everything safe (Temporary Files, Recycle Bin, Windows Update Cleanup, Delivery Optimization Files, Old Windows Installations)
# Then :
cleanmgr /sagerun:1
```

### 1.2 Storage Sense (Windows 10/11 auto-cleanup)
```powershell
# Open Settings -> System -> Storage -> Storage Sense
# Turn it ON, set to clean :
#  - Temporary files weekly
#  - Recycle Bin every 14 days
#  - Downloads after 60 days
```

### 1.3 Remove bloatware / unused apps
```powershell
# List installed apps (sort by size)
Get-AppxPackage | Select-Object Name, PackageFullName | Out-GridView
# Or just :
appwiz.cpl
# Uninstall what you don't use : games trial, OEM tools, Cortana clutter, Xbox stuff
```

### 1.4 Disable hibernation (frees ~12 GB on the C: drive if your machine has 16 GB RAM)
```powershell
# Run as Administrator
powercfg /hibernate off
```

---

## 2. Move user data to external drive

If your C: drive is small (< 256 GB), move Documents/Pictures/Videos to an external drive.

```powershell
# Plug in external drive, note its letter (e.g. E:)
# Method : Right-click each folder (Documents, Pictures, Videos, Downloads) in File Explorer
#   -> Properties -> Location tab -> Move... -> point to E:\Documents (etc.)
# Windows will copy + redirect. Future writes go to E:.
```

**Caution** : if E: drive is unplugged, those folders are inaccessible. Use only if drive will stay plugged in 24/7.

---

## 3. Move Ollama models to external/dedicated drive

Gemma 4 MoE = ~26 GB. Plus other models. Move the Ollama models directory to a drive with space :

```powershell
# Set the OLLAMA_MODELS env var BEFORE first model pull
# (Already in install.ps1 step 0, just uncomment and set the path)
[System.Environment]::SetEnvironmentVariable('OLLAMA_MODELS', 'D:\ollama-models', 'User')

# If models are already on C:, copy them and update var :
robocopy "$env:USERPROFILE\.ollama\models" "D:\ollama-models" /MIR
# Then restart Ollama (system tray -> Quit -> relaunch)
```

---

## 4. Free up RAM — disable startup apps

Press `Ctrl+Shift+Esc` to open Task Manager → **Startup** tab → disable everything you don't need at boot.

Common offenders (safe to disable for a dedicated server) :
- OneDrive (unless you actually use it)
- Microsoft Teams
- Spotify, Discord, etc.
- Cortana
- Skype
- Windows Security notification icon
- OEM bloatware (HP Customer Experience Improvement Program, etc.)

**Keep enabled** :
- Tailscale (you need this for the mesh)
- Ollama (if you set it as startup app)

---

## 5. Disable unnecessary Windows services

```powershell
# Run as Administrator. Disabling these saves RAM + CPU :

# Windows Search indexing (saves ~300 MB RAM, you don't need fast file search on a server)
Set-Service -Name WSearch -StartupType Disabled
Stop-Service -Name WSearch -Force

# SysMain (formerly Superfetch — useful on slow HDD, useless on SSD)
Set-Service -Name SysMain -StartupType Disabled
Stop-Service -Name SysMain -Force

# Print Spooler (if no printer)
Set-Service -Name Spooler -StartupType Disabled
Stop-Service -Name Spooler -Force

# Connected User Experiences and Telemetry (privacy + RAM)
Set-Service -Name DiagTrack -StartupType Disabled
Stop-Service -Name DiagTrack -Force
```

Reboot after this batch.

---

## 6. Power settings — stay awake 24/7

A server needs to NEVER sleep.

```powershell
# Set High Performance power plan
powercfg /setactive SCHEME_MIN

# Never sleep, never turn off display, never hibernate
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
powercfg /change monitor-timeout-ac 0
powercfg /change monitor-timeout-dc 0
powercfg /change hibernate-timeout-ac 0
powercfg /change hibernate-timeout-dc 0
```

Also check : **Settings → System → Power & sleep** — set everything to "Never".

**Lid close action** (laptop) : Settings → Control Panel → Power Options → "Choose what closing the lid does" → "Do nothing" for both AC and battery (if you'll close the lid and let it stay plugged in).

---

## 7. Disable Windows visual effects (free a tiny bit of RAM + GPU)

```powershell
# Run :
SystemPropertiesPerformance.exe
# UI -> Visual Effects tab -> Adjust for best performance
# Or only keep : smooth edges of screen fonts + show thumbnails instead of icons
```

---

## 8. Set up auto-restart of Ollama on boot

Ollama installs itself as a startup app by default. Verify :

```powershell
# Task Manager -> Startup tab -> "ollama" should be Enabled
# If not, right-click it -> Enable
```

If Ollama doesn't auto-start :

```powershell
# Add a startup shortcut manually :
$startup = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$startup\Ollama.lnk")
$Shortcut.TargetPath = "$env:LOCALAPPDATA\Programs\Ollama\ollama app.exe"
$Shortcut.Save()
```

---

## 9. Optional : page file (virtual memory)

If you only have 16 GB RAM and run big models, having a generous page file on a fast SSD helps avoid hard crashes when RAM is full.

```powershell
# Set page file : Initial 8192 MB, Max 16384 MB on C: (or your fast SSD)
# UI : SystemPropertiesAdvanced.exe -> Advanced tab -> Performance Settings -> Advanced -> Virtual Memory -> Change
```

Don't set it on an HDD — it'll be too slow.

---

## 10. Verify after reboot

After all the above, reboot. Then check :

```powershell
# Free RAM
Get-CimInstance Win32_OperatingSystem | Select-Object @{N='Free RAM (GB)';E={[Math]::Round($_.FreePhysicalMemory/1MB,2)}}, @{N='Total RAM (GB)';E={[Math]::Round($_.TotalVisibleMemorySize/1MB,2)}}

# Free disk
Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{N='Free GB';E={[Math]::Round($_.Free/1GB,2)}}, @{N='Used GB';E={[Math]::Round($_.Used/1GB,2)}}
```

Target after cleanup :
- Free RAM at idle : **≥ 12 GB** (out of 16 GB)
- Free disk on C: : **≥ 60 GB** if storing models on C:, or **≥ 20 GB** if models go to external/D:

If you hit those targets, your machine is ready to be a Gemma server.

---

## Recap : minimum steps if you're in a hurry

1. `powercfg /hibernate off` (free disk space)
2. `cleanmgr` (run disk cleanup, check all safe options)
3. Task Manager → Startup → disable everything you don't need at boot
4. `powercfg` commands above (never sleep)
5. Set `OLLAMA_MODELS` to external drive if your C: is tight
6. Reboot
7. Run `install.ps1`

That's it. The rest are optimizations you can do later when you want to squeeze more performance.

---

## Document what worked / didn't on YOUR machine

If you hit something specific to your model (HP Pavilion XYZ, weird OEM service, etc.), log it in [`../../docs/TROUBLESHOOTING.md`](../../docs/TROUBLESHOOTING.md) so the next person doesn't have to figure it out.
