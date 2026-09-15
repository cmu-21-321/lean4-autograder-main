import AutograderLib

/-!
Assignment template ("sheet") used by `tests/run_tests.sh`.

This is a stand-in for a real instructor-authored problem set: it exercises every
autograder attribute (`autogradedProof`, `autogradedDef`, `validAxioms`,
`validTactics`, `defaultTactics`, fractional point values) so that an end-to-end
grading run touches every code path in `Main.lean`. It deliberately imports only
`AutograderLib`, never Mathlib, so CI stays fast.

NOTE: the comment has to come *after* the `import`, not before it. `Main.lean`'s
`splitLeadingImports` recognises only blank lines and `import` lines as part of a
sheet's header, so a sheet that opens with a comment has its `import`s swept into
the body of the generated `ComparatorGrading/Ref.lean`, which then fails to
compile and sinks every definition exercise.
-/

@[defaultTactics #[rfl, simp]]
def setDefaultTactics := ()

-- Proof exercises ------------------------------------------------------------

@[autogradedProof 1]
theorem p_and_comm (p q : Prop) (h : p ∧ q) : q ∧ p := sorry

/-- Fractional point values go through `Float.ofScientific`. -/
@[autogradedProof 2.5]
theorem p_or_comm (p q : Prop) (h : p ∨ q) : q ∨ p := sorry

/-- `Classical.choice` is excluded here, so a classical proof must be rejected. -/
@[autogradedProof 1, validAxioms #[Quot.sound, propext, funext]]
theorem p_nn (p : Prop) (h : p) : ¬¬p := sorry

/-- Exercises `@[validAxioms]` in the *positive* direction. `validAxioms` replaces
`defaultValidAxioms` outright rather than narrowing it, so the reference proof
below is accepted only if the listed names survive `AutograderLib`'s
`Syntax`-to-`Name` parsing and the round-trip through Comparator's JSON config; a
garbled name would reject a correct proof.

`Quot.sound` has to be listed even though the proof never mentions it: `funext` is
a *theorem* in Lean core, not an axiom, and it is derived from `Quot.sound`. -/
@[autogradedProof 1, validAxioms #[Quot.sound, propext, funext]]
theorem p_ext (f g : Nat → Prop) (h : ∀ n, f n ↔ g n) : f = g := sorry

/-- No `validAxioms`, so `defaultValidAxioms` applies and `Classical.choice` is fine. -/
@[autogradedProof 1]
theorem p_em (p : Prop) : p ∨ ¬p := sorry

-- Definition exercises --------------------------------------------------------

@[autogradedDef 1]
def dbl (n : Nat) : Nat := n + n

/-- Polymorphic: exercises `renderType`'s `pp.fullNames`/`pp.universes` rendering
and the `@`-prefixed pin statement. -/
@[autogradedDef 1]
def myId {α : Type u} (a : α) : α := a

/-- `Prop`-valued definition. -/
@[autogradedDef 1]
def IsEven (n : Nat) : Prop := ∃ k, n = 2 * k

/-- Per-exercise `validTactics` override; `run_tests.sh` asserts this tactic text
is spliced verbatim into the generated pin theorem. -/
@[autogradedDef 1, validTactics #[simp [dbl2]]]
def dbl2 (n : Nat) : Nat := 2 * n

/-- Instances are definitions too. -/
@[autogradedDef 1]
instance instReprBoolTF : Repr Bool := ⟨fun b _ => if b then "T" else "F"⟩
