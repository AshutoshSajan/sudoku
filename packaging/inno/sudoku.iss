; Sudoku Windows installer (built by release.yaml via Inno Setup 6).
; AppVersion is injected with /DAppVersion=X.Y.Z. The AppId below is a
; permanent install identity: never change it or upgrades break.
#ifndef AppVersion
#define AppVersion "0.0.0"
#endif

[Setup]
AppId={{8F3E2A1B-5C4D-4E6F-9A0B-1C2D3E4F506A}
AppName=Sudoku
AppVersion={#AppVersion}
AppPublisher=Ashutosh Sajan
AppPublisherURL=https://github.com/AshutoshSajan/sudoku
AppSupportURL=https://github.com/AshutoshSajan/sudoku/issues
DefaultDirName={autopf}\Sudoku
DisableProgramGroupPage=yes
ArchitecturesAllowed=x64compatible
OutputBaseFilename=sudoku-setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\sudoku.exe
VersionInfoVersion={#AppVersion}
LicenseFile=..\..\LICENSE

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{autoprograms}\Sudoku"; Filename: "{app}\sudoku.exe"
Name: "{autodesktop}\Sudoku"; Filename: "{app}\sudoku.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; Flags: unchecked

[Run]
Filename: "{app}\sudoku.exe"; Description: "Launch Sudoku"; Flags: nowait postinstall skipifsilent
