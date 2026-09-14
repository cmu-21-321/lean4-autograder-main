import Lake
open Lake DSL

package autograder

require comparator from git "https://github.com/leanprover/comparator" @ "v4.34.0-rc2"

lean_lib AutograderTests where
  globs := #[.submodules `AutograderTests]

lean_lib ComparatorGrading where
  globs := #[.submodules `ComparatorGrading]

-- Only AutograderLib -- which registers custom attributes/syntax via `initialize`
-- blocks -- needs to be precompiled to a native shared library. AutograderTests and
-- ComparatorGrading must NOT inherit this (as they did when it was set package-wide):
-- with the comparator/lean4export dependencies now in the workspace, precompiling a
-- module that imports Mathlib routes its build through Lake's `--setup ... --json`
-- precompiled-module code path, which -- in this workspace -- fails to compute a
-- correct LD_LIBRARY_PATH (it's missing either the toolchain's own `lib/lean`,
-- where `libLake_shared.so` lives, or a transitive dependency's shared library,
-- depending on what's already in the environment). Plain (non-precompiled) builds
-- of the same modules are unaffected.
lean_lib AutograderLib where
  precompileModules := true

@[default_target]
lean_exe autograder where
  root := `Main
  supportInterpreter := true
