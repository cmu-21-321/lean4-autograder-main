# Lean 4 Gradescope Autograder

This project provides a Lean 4 autograder that works with [Gradescope](https://gradescope-autograders.readthedocs.io/en/latest/). 
It checks that students have provided proof terms with the correct type or have created equal `Expr`s up to definitional equality. 
The autograder can check theorems, functions, propositions, and instances. It *cannot* grade inductive types or structures.

Grading verdicts are independently verified using [Comparator](https://github.com/leanprover/comparator): rather than trusting
its own in-process elaboration of a submission, the autograder rebuilds the relevant declarations in a sandboxed subprocess
(via [landrun](https://github.com/Zouuup/landrun)), re-serializes them through `lean4export`, and replays them through the
Lean kernel. To run the autograder locally (`--local`/`--test`), `landrun` and `lean4export` must be available -- either on
`PATH`, or pointed to via the `COMPARATOR_LANDRUN`/`COMPARATOR_LEAN4EXPORT` environment variables. For local development
without a real sandbox, Comparator's own `scripts/fake-landrun.sh` shim can stand in for `landrun` (no sandboxing, so don't
use it against untrusted submissions).

## Setup 

More detailed instructions can be found in the [Lean autograder shell](https://github.com/robertylewis/lean4_autograder), but here is a brief overview.

First, set up a course repository on GitHub. Add this project, autograder-main, as a lake dependency. 
Then, use [autograder shell](https://github.com/robertylewis/lean4_autograder) to create the zip file that actually gets uploaded to Gradescope.
This project is meant to work with MathLib assignments, so for a good Gradescope performance, their container must have at least 2.0 CPU and 3.0GB RAM,
and preferably the maximum resources allowed by Gradescope.
Otherwise, you'll get inscrutable errors when it runs out of memory. 
After this is all set up, students will only need to submit a file to Gradescope.

For an example, see the repository [fpv2023](https://github.com/BrownCS1951x/fpv2023). 
The lakefile of this project imports this autograder project.
To create a Gradescope assignment for HW1, edit the configuration file in the autograder shell 
to point at `Homeworks/Homework1.lean` in that repository, run the `make_autograder.sh` script, 
and upload the resulting zip file to Gradescope.
Students would then submit *only* their `Homework1.lean` file to Gradescope.

## Autograding 

The primary feature of the current autograder checks that *proofs* are complete. 
An experimental feature checks the correctness of definitions.

### Checking proofs

The attribute `@[autogradedProof pts]` is used to denote exercises where the student should complete a proof of a theorem statement provided by the instructor.
The autograder awards `pts` number of points if the student's proof is complete.
The solution/stencil file needs the theorem statement, but does not need a reference proof of the theorem.

For example, suppose that the stencil distributed to students contains the following code:
```lean
@[autogradedProof 1]
theorem th3 (h : ¬q → ¬p) : (p → q) := sorry
```
If a student submits an assignment that replaces `sorry` with a valid proof, the autograder will grant one point.

By default, the autograder allows all and only the axioms defined in Lean core.
Extra axioms can be allowed globally by tagging the axiom with the `@[legalAxiom]` attribute.
You can locally specify the axioms allowed in a solution by using the `validAxioms` attribute on that problem.
The autograder will only award points for the following if a student's solution does not use `Classical.choice`:
```lean 
@[autogradedProof 1, validAxioms #[Quot.sound, propext, funext]]
theorem EM_of_DN_good : (∀ p : Prop, ¬¬p → p) → (∀ p : Prop, p ∨ ¬p) :=
  sorry
```

### Checking definitions

**This feature is experimental.** It should not be relied on yet.

The attribute `@[autogradedDef pts]` applies to functions, propositions, and instances, i.e. declarations whose type is not a `Prop`.
The correct declaration body must be provided in the solution file.
The autograder will try to prove that the student's definition is equal to the solution definition using `Eq.refl`, `HEq.refl`, and various tactics.
A default list of tactics for the assignment can be set using `@[defaultTactics #[]]` over the `setDefaultTactics` function.
Individual problems can override the default list of tactics using the `@[validTactics #[]]` attribute. 

For example, the autograder would award 2 points for a definition of `reverse` that is equal to the solution definition below.
It will only use `rfl` to prove the equality.

```lean
@[defaultTactics #[rfl, simp]] 
def setDefaultTactics := () 

@[autogradedDef 2, validTactics #[rfl]]
def reverse {α : Type} : List α → List α
  | List.nil        => List.nil
  | List.cons x xs  => List.append (reverse xs) [x]
```

## Testing the Autograder

To run the autograder locally, build the project and run the autograder with the `--local` flag.
This will print the results of the autograder to the console instead of producing a JSON file.

```lean
lake exe autograder --local path/to/submission.lean path/to/solutions.lean
```

### Building a test suite

More comprehensive testing can be desirable especially during assignment development.
To test the autograder, build the project and run the autograder with the `--test` flag.
This will check the submission sheet for the `[@autograderTest status name]` attribute.

The `autograderTest` attribute is used to test multiple possible submissions to a problem
without editing the master solutions file. The `status` parameter is the expected status 
of the test and should either be `passes` or `fails`. The `name` parameter is the name of 
the problem in the solutions files. 

Here is an example of a solution and test file for the `reverse` function.

```lean
-- Solutions file
@[autogradedDef 1, validTactics #[custom_simp]]
def reverse {α : Type} : List α → List α
  | List.nil        => List.nil
  | List.cons x xs  => List.append (reverse xs) [x]
```

```lean
-- Test file
-- Exactly the same
@[autograderTest passes `reverse]
def reverse {α : Type} : List α → List α
  | List.nil        => List.nil
  | List.cons x xs  => List.append (reverse xs) [x]

-- Different but correct implementation
@[autograderTest passes `reverse]
def reverse2 {α : Type} (lst: List α) : List α := 
  lst.foldr (fun x acc => acc ++ [x]) []

-- Wrong implementation
@[autograderTest fails `reverse]
def reverse3 {α : Type} : List α → List α
  | List.nil        => List.nil
  | List.cons x xs  => List.append [x] (reverse3 xs)
```
