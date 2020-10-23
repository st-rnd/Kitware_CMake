cmake_minimum_required(VERSION 3.19) # CMP0053

include(RunCMake)

# Fix Visual Studio generator name
if(RunCMake_GENERATOR MATCHES "^(Visual Studio [0-9]+ [0-9]+) ")
  set(RunCMake_GENERATOR "${CMAKE_MATCH_1}")
endif()

set(RunCMake-check-file check.cmake)

function(validate_schema file expected_result)
  execute_process(
    COMMAND "${PYTHON_EXECUTABLE}" "${RunCMake_SOURCE_DIR}/validate_schema.py" "${file}"
    RESULT_VARIABLE _result
    OUTPUT_VARIABLE _output
    ERROR_VARIABLE _error
    )
  if(NOT _result STREQUAL expected_result)
    string(REPLACE "\n" "\n" _output_p "${_output}")
    string(REPLACE "\n" "\n" _error_p "${_error}")
    string(APPEND RunCMake_TEST_FAILED "Expected result of validating ${file}: ${expected_result}\nActual result: ${_result}\nOutput:\n${_output_p}\nError:\n${_error_p}")
  endif()

  set(RunCMake_TEST_FAILED "${RunCMake_TEST_FAILED}" PARENT_SCOPE)
endfunction()

function(run_cmake_presets name)
  set(RunCMake_TEST_SOURCE_DIR "${RunCMake_BINARY_DIR}/${name}")
  set(_source_arg "${RunCMake_TEST_SOURCE_DIR}")
  if(CMakePresets_RELATIVE_SOURCE)
    set(_source_arg "../${name}")
  endif()
  file(REMOVE_RECURSE "${RunCMake_TEST_SOURCE_DIR}")
  file(MAKE_DIRECTORY "${RunCMake_TEST_SOURCE_DIR}")
  configure_file("${RunCMake_SOURCE_DIR}/CMakeLists.txt.in" "${RunCMake_TEST_SOURCE_DIR}/CMakeLists.txt" @ONLY)

  if(NOT CMakePresets_FILE)
    set(CMakePresets_FILE "${RunCMake_SOURCE_DIR}/${name}.json.in")
  endif()
  if(EXISTS "${CMakePresets_FILE}")
    configure_file("${CMakePresets_FILE}" "${RunCMake_TEST_SOURCE_DIR}/CMakePresets.json" @ONLY)
  endif()

  if(NOT CMakeUserPresets_FILE)
    set(CMakeUserPresets_FILE "${RunCMake_SOURCE_DIR}/${name}User.json.in")
  endif()
  if(EXISTS "${CMakeUserPresets_FILE}")
    configure_file("${CMakeUserPresets_FILE}" "${RunCMake_TEST_SOURCE_DIR}/CMakeUserPresets.json" @ONLY)
  endif()

  set(_s_arg -S)
  if(CMakePresets_NO_S_ARG)
    set(_s_arg)
  endif()
  set(_source_args ${_s_arg} ${_source_arg})
  if(CMakePresets_NO_SOURCE_ARGS)
    set(_source_args)
  endif()
  set(_unused_cli --no-warn-unused-cli)
  if(CMakePresets_WARN_UNUSED_CLI)
    set(_unused_cli)
  endif()

  set(RunCMake_TEST_COMMAND ${CMAKE_COMMAND}
    ${_source_args}
    -DRunCMake_TEST=${name}
    -DRunCMake_GENERATOR=${RunCMake_GENERATOR}
    -DCMAKE_MAKE_PROGRAM=${RunCMake_MAKE_PROGRAM}
    ${_unused_cli}
    --preset=${name}
    ${ARGN}
    )
  run_cmake(${name})
endfunction()

# Test CMakePresets.json errors
set(CMakePresets_SCHEMA_EXPECTED_RESULT 1)
run_cmake_presets(NoCMakePresets)
run_cmake_presets(JSONParseError)
run_cmake_presets(InvalidRoot)
run_cmake_presets(NoVersion)
run_cmake_presets(InvalidVersion)
run_cmake_presets(LowVersion)
run_cmake_presets(HighVersion)
run_cmake_presets(InvalidVendor)
set(CMakePresets_SCHEMA_EXPECTED_RESULT 0)
run_cmake_presets(NoPresets)
set(CMakePresets_SCHEMA_EXPECTED_RESULT 1)
run_cmake_presets(InvalidPresets)
run_cmake_presets(PresetNotObject)
run_cmake_presets(NoPresetName)
run_cmake_presets(InvalidPresetName)
run_cmake_presets(EmptyPresetName)
set(CMakePresets_SCHEMA_EXPECTED_RESULT 0)
run_cmake_presets(NoPresetGenerator)
set(CMakePresets_SCHEMA_EXPECTED_RESULT 1)
run_cmake_presets(InvalidPresetGenerator)
set(CMakePresets_SCHEMA_EXPECTED_RESULT 0)
run_cmake_presets(NoPresetBinaryDir)
set(CMakePresets_SCHEMA_EXPECTED_RESULT 1)
run_cmake_presets(InvalidPresetBinaryDir)
run_cmake_presets(InvalidVariables)
run_cmake_presets(VariableNotObject)
run_cmake_presets(NoVariableValue)
run_cmake_presets(InvalidVariableValue)
run_cmake_presets(ExtraRootField)
run_cmake_presets(ExtraPresetField)
run_cmake_presets(ExtraVariableField)
run_cmake_presets(InvalidPresetVendor)
set(CMakePresets_SCHEMA_EXPECTED_RESULT 0)
run_cmake_presets(DuplicatePresets)
run_cmake_presets(CyclicInheritance0)
run_cmake_presets(CyclicInheritance1)
run_cmake_presets(CyclicInheritance2)
run_cmake_presets(InvalidInheritance)
run_cmake_presets(ErrorNoWarningDev)
run_cmake_presets(ErrorNoWarningDeprecated)
set(CMakePresets_SCHEMA_EXPECTED_RESULT 1)
run_cmake_presets(InvalidArchitectureStrategy)
run_cmake_presets(UnknownArchitectureStrategy)
run_cmake_presets(InvalidToolsetStrategy)
run_cmake_presets(UnknownToolsetStrategy)
run_cmake_presets(EmptyCacheKey)
run_cmake_presets(EmptyEnvKey)
set(CMakePresets_SCHEMA_EXPECTED_RESULT 0)
run_cmake_presets(UnclosedMacro)
run_cmake_presets(NoSuchMacro)
run_cmake_presets(EnvCycle)
run_cmake_presets(EmptyEnv)
run_cmake_presets(EmptyPenv)
set(CMakePresets_SCHEMA_EXPECTED_RESULT 1)

# Test cmakeMinimumRequired field
run_cmake_presets(MinimumRequiredInvalid)
set(CMakePresets_SCHEMA_EXPECTED_RESULT 0)
run_cmake_presets(MinimumRequiredEmpty)
run_cmake_presets(MinimumRequiredMajor)
run_cmake_presets(MinimumRequiredMinor)
run_cmake_presets(MinimumRequiredPatch)

# Test properly working CMakePresets.json
set(CMakePresets_FILE "${RunCMake_SOURCE_DIR}/CMakePresets.json.in")
unset(ENV{TEST_ENV})
unset(ENV{TEST_ENV_REF})
unset(ENV{TEST_D_ENV_REF})
set(ENV{TEST_ENV_OVERRIDE} "This environment variable will be overridden")
set(ENV{TEST_PENV} "Process environment variable")
set(ENV{TEST_ENV_REF_PENV} "suffix")
run_cmake_presets(Good "-DTEST_OVERRIDE_1=Overridden value" "-DTEST_OVERRIDE_2:STRING=Overridden value" -C "${RunCMake_SOURCE_DIR}/CacheOverride.cmake" "-UTEST_UNDEF")
unset(ENV{TEST_ENV_OVERRIDE})
unset(ENV{TEST_PENV})
unset(ENV{TEST_ENV_REF_PENV})
run_cmake_presets(GoodNoArgs)
file(REMOVE_RECURSE ${RunCMake_BINARY_DIR}/GoodBinaryUp-build)
run_cmake_presets(GoodBinaryUp)
set(CMakePresets_RELATIVE_SOURCE TRUE)
run_cmake_presets(GoodBinaryRelative)
unset(CMakePresets_RELATIVE_SOURCE)
run_cmake_presets(GoodSpaces "--preset=Good Spaces")
if(WIN32)
  run_cmake_presets(GoodWindowsBackslash)
endif()
set(CMakePresets_FILE "${RunCMake_SOURCE_DIR}/GoodBOM.json.in")
run_cmake_presets(GoodBOM)
set(CMakePresets_FILE "${RunCMake_SOURCE_DIR}/CMakePresets.json.in")
file(REMOVE_RECURSE ${RunCMake_BINARY_DIR}/GoodBinaryCmdLine-build)
run_cmake_presets(GoodBinaryCmdLine -B ${RunCMake_BINARY_DIR}/GoodBinaryCmdLine-build)
run_cmake_presets(GoodGeneratorCmdLine -G ${RunCMake_GENERATOR})
run_cmake_presets(InvalidGeneratorCmdLine -G "Invalid Generator")
set(CMakePresets_NO_S_ARG TRUE)
run_cmake_presets(GoodNoS)
unset(CMakePresets_NO_S_ARG)
run_cmake_presets(GoodInheritanceParent)
run_cmake_presets(GoodInheritanceChild)
run_cmake_presets(GoodInheritanceOverride)
run_cmake_presets(GoodInheritanceMulti)
run_cmake_presets(GoodInheritanceMultiSecond)
run_cmake_presets(GoodInheritanceMacro)

# Test bad preset arguments
run_cmake_presets(VendorMacro)
run_cmake_presets(InvalidGenerator)

# Test Visual Studio-specific stuff
if(RunCMake_GENERATOR MATCHES "^Visual Studio ")
  run_cmake_presets(VisualStudioGeneratorArch)
  run_cmake_presets(VisualStudioWin32)
  run_cmake_presets(VisualStudioWin64)
  run_cmake_presets(VisualStudioWin32Override -A x64)
  if(NOT RunCMake_GENERATOR STREQUAL "Visual Studio 9 2008")
    run_cmake_presets(VisualStudioToolset)
    run_cmake_presets(VisualStudioToolsetOverride -T "Test Toolset")
    run_cmake_presets(VisualStudioInheritanceParent)
    run_cmake_presets(VisualStudioInheritanceChild)
    run_cmake_presets(VisualStudioInheritanceOverride)
    run_cmake_presets(VisualStudioInheritanceMulti)
    run_cmake_presets(VisualStudioInheritanceMultiSecond)
  endif()
else()
  run_cmake_presets(ArchToolsetStrategyNone)
  run_cmake_presets(ArchToolsetStrategyDefault)
  run_cmake_presets(ArchToolsetStrategyIgnore)
endif()

# Test bad command line arguments
run_cmake_presets(NoSuchPreset)
run_cmake_presets(NoPresetArgument --preset=)
run_cmake_presets(UseHiddenPreset)

# Test CMakeUserPresets.json
unset(CMakePresets_FILE)
run_cmake_presets(GoodUserOnly)
run_cmake_presets(GoodUserFromMain)
run_cmake_presets(GoodUserFromUser)

# Test CMakeUserPresets.json errors
run_cmake_presets(UserDuplicateInUser)
run_cmake_presets(UserDuplicateCross)
run_cmake_presets(UserInheritance)

# Test listing presets
set(CMakePresets_FILE "${RunCMake_SOURCE_DIR}/ListPresets.json.in")
run_cmake_presets(ListPresets --list-presets)

set(RunCMake_TEST_BINARY_DIR "${RunCMake_BINARY_DIR}/ListPresetsWorkingDir")
set(RunCMake_TEST_NO_CLEAN 1)
set(CMakePresets_NO_SOURCE_ARGS 1)
run_cmake_presets(ListPresetsWorkingDir --list-presets)
unset(CMakePresets_NO_SOURCE_ARGS)
unset(RunCMake_TEST_NO_CLEAN)
unset(RunCMake_TEST_BINARY_DIR)

run_cmake_presets(ListPresetsNoSuchPreset)
run_cmake_presets(ListPresetsHidden)

# Test warning and error flags
set(CMakePresets_FILE "${RunCMake_SOURCE_DIR}/Warnings.json.in")
set(CMakePresets_WARN_UNUSED_CLI 1)
run_cmake_presets(NoWarningFlags)
run_cmake_presets(WarningFlags)
run_cmake_presets(DisableWarningFlags)
run_cmake_presets(ErrorDev)
run_cmake_presets(ErrorDeprecated)
unset(CMakePresets_WARN_UNUSED_CLI)

# Test debug
set(CMakePresets_FILE "${RunCMake_SOURCE_DIR}/Debug.json.in")
run_cmake_presets(NoDebug)
run_cmake_presets(Debug)

# Test the example from the documentation
file(READ "${RunCMake_SOURCE_DIR}/../../../Help/manual/presets/example.json" _example)
string(REPLACE "\"generator\": \"Ninja\"" "\"generator\": \"@RunCMake_GENERATOR@\"" _example "${_example}")
file(WRITE "${RunCMake_BINARY_DIR}/example.json.in" "${_example}")
set(CMakePresets_FILE "${RunCMake_BINARY_DIR}/example.json.in")
run_cmake_presets(DocumentationExample --preset=default)
