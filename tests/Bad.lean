import AutograderLib

/-!
A submission that must be *rejected* on most exercises in `tests/Sheet.lean`.

This is the safety-critical direction: a regression that makes the autograder
accept these would silently hand out points for wrong work. `p_and_comm`,
`p_em` and `myId` are correct on purpose, as controls.
-/

-- Control: correct, must still pass.
theorem p_and_comm (p q : Prop) (h : p ∧ q) : q ∧ p := ⟨h.2, h.1⟩

-- Incomplete: must be rejected for `sorryAx`.
theorem p_or_comm (p q : Prop) (h : p ∨ q) : q ∨ p := sorry

-- Correct, but classical; `p_nn`'s `validAxioms` forbids `Classical.choice`.
theorem p_nn (p : Prop) (h : p) : ¬¬p :=
  fun hn => (Classical.em p).elim (fun _ => hn h) (fun np => np h)

-- Correct, but routed through `Classical.choice`, which `p_ext`'s `validAxioms`
-- omits: must be rejected even though `propext` and `funext` are permitted.
theorem p_ext (f g : Nat → Prop) (h : ∀ n, f n ↔ g n) : f = g :=
  Classical.byContradiction fun hne => hne (funext fun n => propext (h n))

-- Control: classical is permitted here, must still pass.
theorem p_em (p : Prop) : p ∨ ¬p := Classical.em p

-- Extensionally equal but not definitionally so: must be rejected.
def dbl (n : Nat) : Nat := n * 2

-- Control: identical to the reference, must still pass.
def myId {α : Type u} (a : α) : α := a

-- Equivalent but not definitionally equal: must be rejected.
def IsEven (n : Nat) : Prop := ∃ k, n = k + k

def dbl2 (n : Nat) : Nat := n + n

-- Observably different behaviour: must be rejected.
instance instReprBoolTF : Repr Bool := ⟨fun b _ => if b then "F" else "T"⟩
