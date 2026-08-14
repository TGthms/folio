#!/usr/bin/env python3
"""Generate Folio.xcodeproj without XcodeGen."""
from __future__ import annotations

import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "Folio.xcodeproj"

LOCALES = [
    "en", "es", "fr", "de", "it", "pt-BR", "pt-PT", "nl", "da", "sv", "nb", "fi",
    "pl", "cs", "hu", "ro", "el", "tr", "ru", "uk", "ar", "he", "hi", "th", "vi",
    "id", "ja", "ko", "zh-Hans", "zh-Hant", "Base",
]


def pid(name: str) -> str:
    return hashlib.sha1(name.encode()).hexdigest()[:24].upper()


def quote(value: str) -> str:
    if value and all(c.isalnum() or c in "._-" for c in value):
        return value
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def collect(rel_dir: str, exts: set[str]) -> list[Path]:
    base = ROOT / rel_dir
    files: list[Path] = []
    for path in sorted(base.rglob("*")):
        if path.is_file() and path.suffix in exts:
            files.append(path.relative_to(ROOT))
    return files


app_sources = collect("Folio", {".swift"})
test_sources = collect("FolioTests", {".swift"})
logic_sources = [
    Path("FolioLogicTests/ProtectWriteTests.swift"),
    Path("Folio/Models/FolioError.swift"),
    Path("Folio/Models/ExportOptions.swift"),
    Path("Folio/Models/PageRef.swift"),
    Path("Folio/Services/PDFPageGraphics.swift"),
    Path("Folio/Services/PDFIO.swift"),
]
resources = [
    Path("Folio/Resources/Assets.xcassets"),
    Path("Folio/Localization/Localizable.xcstrings"),
]

objects: dict[str, str] = {}


def add(key: str, body: str) -> str:
    objects[key] = body
    return key


file_refs: dict[str, str] = {}


def file_ref(path: Path, ftype: str | None = None) -> str:
    key = pid(f"ref:{path}")
    if key in objects:
        return key
    if ftype is None:
        if path.suffix == ".swift":
            ftype = "sourcecode.swift"
        elif path.suffix == ".plist":
            ftype = "text.plist.xml"
        elif path.suffix == ".entitlements":
            ftype = "text.plist.entitlements"
        elif path.suffix == ".xcassets":
            ftype = "folder.assetcatalog"
        elif path.suffix == ".xcstrings":
            ftype = "text.json.xcstrings"
        else:
            ftype = "text"
    add(
        key,
        f"isa = PBXFileReference; lastKnownFileType = {ftype}; name = {quote(path.name)}; path = {quote(str(path))}; sourceTree = SOURCE_ROOT;",
    )
    file_refs[str(path)] = key
    return key


def build_file(path: Path, prefix: str) -> str:
    ref = file_ref(path)
    key = pid(f"build:{prefix}:{path}")
    add(key, f"isa = PBXBuildFile; fileRef = {ref};")
    return key


file_ref(Path("Folio/Resources/Info.plist"))
file_ref(Path("Folio/Resources/Folio.entitlements"))

app_product = add(
    pid("product:Folio.app"),
    "isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Folio.app; sourceTree = BUILT_PRODUCTS_DIR;",
)
test_product = add(
    pid("product:FolioTests.xctest"),
    "isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = FolioTests.xctest; sourceTree = BUILT_PRODUCTS_DIR;",
)
logic_product = add(
    pid("product:FolioLogicTests.xctest"),
    "isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = FolioLogicTests.xctest; sourceTree = BUILT_PRODUCTS_DIR;",
)

app_source_builds = [build_file(p, "app") for p in app_sources]
test_source_builds = [build_file(p, "test") for p in test_sources]
logic_source_builds = [build_file(p, "logic") for p in logic_sources]
resource_builds = [build_file(p, "res") for p in resources]


def group_for(files: list[Path], name: str) -> str:
    children = ", ".join(file_ref(path) for path in files)
    key = pid(f"group-list:{name}")
    add(key, f'isa = PBXGroup; children = ( {children} ); name = {quote(name)}; sourceTree = "<group>";')
    return key


sources_group = group_for(app_sources, "Folio")
tests_group = group_for(test_sources, "FolioTests")
logic_group = group_for([Path("FolioLogicTests/ProtectWriteTests.swift")], "FolioLogicTests")
res_group = group_for(
    [
        Path("Folio/Resources/Info.plist"),
        Path("Folio/Resources/Folio.entitlements"),
        Path("Folio/Resources/Assets.xcassets"),
        Path("Folio/Localization/Localizable.xcstrings"),
    ],
    "Resources",
)
products_group = add(
    pid("group:products"),
    f'isa = PBXGroup; children = ( {app_product}, {test_product}, {logic_product} ); name = Products; sourceTree = "<group>";',
)
main_group = add(
    pid("group:main"),
    f'isa = PBXGroup; children = ( {sources_group}, {tests_group}, {logic_group}, {res_group}, {products_group} ); sourceTree = "<group>";',
)

app_src_phase = add(
    pid("phase:app-src"),
    "isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ( "
    + ", ".join(app_source_builds)
    + " ); runOnlyForDeploymentPostprocessing = 0;",
)
test_src_phase = add(
    pid("phase:test-src"),
    "isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ( "
    + ", ".join(test_source_builds)
    + " ); runOnlyForDeploymentPostprocessing = 0;",
)
logic_src_phase = add(
    pid("phase:logic-src"),
    "isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ( "
    + ", ".join(logic_source_builds)
    + " ); runOnlyForDeploymentPostprocessing = 0;",
)
app_res_phase = add(
    pid("phase:app-res"),
    "isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ( "
    + ", ".join(resource_builds)
    + " ); runOnlyForDeploymentPostprocessing = 0;",
)
test_res_phase = add(
    pid("phase:test-res"),
    "isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ( ); runOnlyForDeploymentPostprocessing = 0;",
)
app_fw_phase = add(
    pid("phase:app-fw"),
    "isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = ( ); runOnlyForDeploymentPostprocessing = 0;",
)
test_fw_phase = add(
    pid("phase:test-fw"),
    "isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = ( ); runOnlyForDeploymentPostprocessing = 0;",
)
logic_fw_phase = add(
    pid("phase:logic-fw"),
    "isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = ( ); runOnlyForDeploymentPostprocessing = 0;",
)
logic_res_phase = add(
    pid("phase:logic-res"),
    "isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ( ); runOnlyForDeploymentPostprocessing = 0;",
)

shared = """
ALWAYS_SEARCH_USER_PATHS = NO;
CLANG_ENABLE_MODULES = YES;
CLANG_ENABLE_OBJC_ARC = YES;
CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
ENABLE_HARDENED_RUNTIME = YES;
MACOSX_DEPLOYMENT_TARGET = 15.0;
SDKROOT = macosx;
SWIFT_VERSION = 6.0;
SWIFT_STRICT_CONCURRENCY = complete;
CODE_SIGN_STYLE = Automatic;
"""

debug = shared + """
COPY_PHASE_STRIP = NO;
DEBUG_INFORMATION_FORMAT = dwarf;
ENABLE_TESTABILITY = YES;
GCC_OPTIMIZATION_LEVEL = 0;
ONLY_ACTIVE_ARCH = YES;
SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
SWIFT_OPTIMIZATION_LEVEL = "-Onone";
"""

release = shared + """
COPY_PHASE_STRIP = NO;
DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
GCC_OPTIMIZATION_LEVEL = s;
SWIFT_COMPILATION_MODE = wholemodule;
SWIFT_OPTIMIZATION_LEVEL = "-O";
"""

proj_debug = add(pid("cfg:proj-debug"), f"isa = XCBuildConfiguration; buildSettings = {{ {debug} }}; name = Debug;")
proj_release = add(pid("cfg:proj-release"), f"isa = XCBuildConfiguration; buildSettings = {{ {release} }}; name = Release;")
proj_cfgs = add(
    pid("list:proj"),
    f"isa = XCConfigurationList; buildConfigurations = ( {proj_debug}, {proj_release} ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Debug;",
)

app_settings = """
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
COMBINE_HIDPI_IMAGES = YES;
CURRENT_PROJECT_VERSION = 1;
GENERATE_INFOPLIST_FILE = NO;
INFOPLIST_FILE = Folio/Resources/Info.plist;
LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/../Frameworks";
MARKETING_VERSION = 1.0;
PRODUCT_BUNDLE_IDENTIFIER = app.folio.mac;
PRODUCT_NAME = Folio;
ENABLE_HARDENED_RUNTIME = YES;
CODE_SIGN_STYLE = Automatic;
ENABLE_APP_SANDBOX = YES;
SWIFT_EMIT_LOC_STRINGS = YES;
"""

test_settings = """
BUNDLE_LOADER = "$(TEST_HOST)";
GENERATE_INFOPLIST_FILE = YES;
PRODUCT_BUNDLE_IDENTIFIER = app.folio.mac.tests;
PRODUCT_NAME = FolioTests;
TEST_HOST = "$(BUILT_PRODUCTS_DIR)/Folio.app/Contents/MacOS/Folio";
LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/../Frameworks @loader_path/../Frameworks";
MACOSX_DEPLOYMENT_TARGET = 15.0;
"""

logic_settings = """
GENERATE_INFOPLIST_FILE = YES;
PRODUCT_BUNDLE_IDENTIFIER = app.folio.mac.logictests;
PRODUCT_NAME = FolioLogicTests;
LD_RUNPATH_SEARCH_PATHS = "$(inherited) @loader_path/../Frameworks";
MACOSX_DEPLOYMENT_TARGET = 15.0;
FRAMEWORK_SEARCH_PATHS = "$(inherited) $(PLATFORM_DIR)/Developer/Library/Frameworks";
CODE_SIGNING_ALLOWED = NO;
"""

app_debug_settings = app_settings + """
CODE_SIGN_ENTITLEMENTS = Folio/Resources/FolioDebug.entitlements;
ENABLE_APP_SANDBOX = NO;
"""
app_release_settings = app_settings + """
CODE_SIGN_ENTITLEMENTS = Folio/Resources/Folio.entitlements;
"""
app_debug = add(pid("cfg:app-debug"), f"isa = XCBuildConfiguration; buildSettings = {{ {app_debug_settings} }}; name = Debug;")
app_release = add(pid("cfg:app-release"), f"isa = XCBuildConfiguration; buildSettings = {{ {app_release_settings} }}; name = Release;")
app_cfgs = add(
    pid("list:app"),
    f"isa = XCConfigurationList; buildConfigurations = ( {app_debug}, {app_release} ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Debug;",
)
test_debug = add(pid("cfg:test-debug"), f"isa = XCBuildConfiguration; buildSettings = {{ {test_settings} }}; name = Debug;")
test_release = add(pid("cfg:test-release"), f"isa = XCBuildConfiguration; buildSettings = {{ {test_settings} }}; name = Release;")
test_cfgs = add(
    pid("list:test"),
    f"isa = XCConfigurationList; buildConfigurations = ( {test_debug}, {test_release} ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Debug;",
)
logic_debug = add(pid("cfg:logic-debug"), f"isa = XCBuildConfiguration; buildSettings = {{ {logic_settings} }}; name = Debug;")
logic_release = add(pid("cfg:logic-release"), f"isa = XCBuildConfiguration; buildSettings = {{ {logic_settings} }}; name = Release;")
logic_cfgs = add(
    pid("list:logic"),
    f"isa = XCConfigurationList; buildConfigurations = ( {logic_debug}, {logic_release} ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Debug;",
)

app_target = add(
    pid("target:app"),
    f"""isa = PBXNativeTarget;
buildConfigurationList = {app_cfgs};
buildPhases = ( {app_src_phase}, {app_fw_phase}, {app_res_phase} );
buildRules = ( );
dependencies = ( );
name = Folio;
productName = Folio;
productReference = {app_product};
productType = "com.apple.product-type.application";
""",
)

container = add(
    pid("proxy:app"),
    f"isa = PBXContainerItemProxy; containerPortal = {pid('project')}; proxyType = 1; remoteGlobalIDString = {app_target}; remoteInfo = Folio;",
)
dependency = add(
    pid("dep:app"),
    f"isa = PBXTargetDependency; target = {app_target}; targetProxy = {container};",
)

test_target = add(
    pid("target:tests"),
    f"""isa = PBXNativeTarget;
buildConfigurationList = {test_cfgs};
buildPhases = ( {test_src_phase}, {test_fw_phase}, {test_res_phase} );
buildRules = ( );
dependencies = ( {dependency} );
name = FolioTests;
productName = FolioTests;
productReference = {test_product};
productType = "com.apple.product-type.bundle.unit-test";
""",
)

logic_target = add(
    pid("target:logic"),
    f"""isa = PBXNativeTarget;
buildConfigurationList = {logic_cfgs};
buildPhases = ( {logic_src_phase}, {logic_fw_phase}, {logic_res_phase} );
buildRules = ( );
dependencies = ( );
name = FolioLogicTests;
productName = FolioLogicTests;
productReference = {logic_product};
productType = "com.apple.product-type.bundle.unit-test";
""",
)

known = ", ".join(LOCALES)
project = add(
    pid("project"),
    f"""isa = PBXProject;
attributes = {{ BuildIndependentTargetsInParallel = 1; LastSwiftUpdateCheck = 2600; LastUpgradeCheck = 2600; }};
buildConfigurationList = {proj_cfgs};
compatibilityVersion = "Xcode 15.0";
developmentRegion = en;
hasScannedForEncodings = 0;
knownRegions = ( {known} );
mainGroup = {main_group};
productRefGroup = {products_group};
projectDirPath = "";
projectRoot = "";
targets = ( {app_target}, {test_target}, {logic_target} );
""",
)

scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2600" version="1.7">
   <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app_target}" BuildableName="Folio.app" BlueprintName="Folio" ReferencedContainer="container:Folio.xcodeproj"/>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES">
      <Testables>
         <TestableReference skipped="NO">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{test_target}" BuildableName="FolioTests.xctest" BlueprintName="FolioTests" ReferencedContainer="container:Folio.xcodeproj"/>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
      <BuildableProductRunnable runnableDebuggingMode="0">
         <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app_target}" BuildableName="Folio.app" BlueprintName="Folio" ReferencedContainer="container:Folio.xcodeproj"/>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES">
      <BuildableProductRunnable runnableDebuggingMode="0">
         <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app_target}" BuildableName="Folio.app" BlueprintName="Folio" ReferencedContainer="container:Folio.xcodeproj"/>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction buildConfiguration="Debug"/>
   <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
"""

sections: dict[str, list[tuple[str, str]]] = {}
for key, body in objects.items():
    isa = body.split("isa = ")[1].split(";")[0].strip()
    sections.setdefault(isa, []).append((key, body))

lines = [
    "// !$*UTF8*$!",
    "{",
    "\tarchiveVersion = 1;",
    "\tclasses = {",
    "\t};",
    "\tobjectVersion = 56;",
    "\tobjects = {",
    "",
]
for isa, items in sections.items():
    lines.append(f"/* Begin {isa} section */")
    for key, body in items:
        compact = " ".join(body.split())
        lines.append(f"\t\t{key} = {{ {compact} }};")
    lines.append(f"/* End {isa} section */")
    lines.append("")

lines += ["\t};", f"\trootObject = {pid('project')};", "}", ""]

PROJECT.mkdir(exist_ok=True)
(PROJECT / "project.pbxproj").write_text("\n".join(lines))
scheme_dir = PROJECT / "xcshareddata" / "xcschemes"
scheme_dir.mkdir(parents=True, exist_ok=True)
(scheme_dir / "Folio.xcscheme").write_text(scheme)
logic_scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2600" version="1.7">
   <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting="YES" buildForRunning="NO" buildForProfiling="NO" buildForArchiving="NO" buildForAnalyzing="YES">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{logic_target}" BuildableName="FolioLogicTests.xctest" BlueprintName="FolioLogicTests" ReferencedContainer="container:Folio.xcodeproj"/>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES">
      <Testables>
         <TestableReference skipped="NO">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{logic_target}" BuildableName="FolioLogicTests.xctest" BlueprintName="FolioLogicTests" ReferencedContainer="container:Folio.xcodeproj"/>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
   </LaunchAction>
   <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES">
   </ProfileAction>
   <AnalyzeAction buildConfiguration="Debug"/>
   <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
"""
(scheme_dir / "FolioLogicTests.xcscheme").write_text(logic_scheme)
print(f"Wrote {PROJECT}")
print(f"App sources: {len(app_sources)} tests: {len(test_sources)}")
