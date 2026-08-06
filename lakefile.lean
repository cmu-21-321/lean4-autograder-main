import Lake
open Lake DSL

package autograder where
  precompileModules := true

require comparator from git "https://github.com/leanprover/comparator" @ "v4.32.0"

lean_lib AutograderTests where
  globs := #[.submodules `AutograderTests]

lean_lib ComparatorGrading where
  globs := #[.submodules `ComparatorGrading]

lean_lib AutograderLib

@[default_target]
lean_exe autograder where
  root := `Main
  supportInterpreter := true
