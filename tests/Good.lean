import AutograderLib

/-! A submission that should receive full marks on every exercise in
`tests/Sheet.lean`. -/

theorem p_and_comm (p q : Prop) (h : p ∧ q) : q ∧ p := ⟨h.2, h.1⟩

theorem p_or_comm (p q : Prop) (h : p ∨ q) : q ∨ p := h.elim Or.inr Or.inl

theorem p_nn (p : Prop) (h : p) : ¬¬p := fun hn => hn h

theorem p_ext (f g : Nat → Prop) (h : ∀ n, f n ↔ g n) : f = g :=
  funext fun n => propext (h n)

theorem p_em (p : Prop) : p ∨ ¬p := Classical.em p

def dbl (n : Nat) : Nat := n + n

def myId {α : Type u} (a : α) : α := a

def IsEven (n : Nat) : Prop := ∃ k, n = 2 * k

def dbl2 (n : Nat) : Nat := 2 * n

instance instReprBoolTF : Repr Bool := ⟨fun b _ => if b then "T" else "F"⟩
