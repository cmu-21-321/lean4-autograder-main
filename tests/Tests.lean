import AutograderLib

/-!
Fixture for `--test` mode: candidate submissions tagged with `autograderTest`,
each declaring whether it is expected to pass or fail the named sheet exercise.
`run_tests.sh` asserts that every expectation is met.
-/

@[autograderTest passes `p_and_comm]
theorem t_pac_ok (p q : Prop) (h : p ∧ q) : q ∧ p := ⟨h.2, h.1⟩

@[autograderTest fails `p_and_comm]
theorem t_pac_sorry (p q : Prop) (h : p ∧ q) : q ∧ p := sorry

@[autograderTest passes `dbl]
def t_dbl_ok (n : Nat) : Nat := n + n

@[autograderTest fails `dbl]
def t_dbl_bad (n : Nat) : Nat := n * 3

@[autograderTest passes `myId]
def t_id_ok {α : Type u} (a : α) : α := a

@[autograderTest passes `IsEven]
def t_iseven_ok (n : Nat) : Prop := ∃ k, n = 2 * k
