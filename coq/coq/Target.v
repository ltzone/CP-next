Require Import LibTactics.
Require Import Metalib.Metatheory.
Require Import List. Import ListNotations.
Require Import Arith Lia.
Require Import rules_inf.
Require Import rules_inf2.


Declare Custom Entry stlc.
Declare Custom Entry stlc_ty.

Notation "G ||- t : T" := (target_typing G t T) (at level 40, t custom stlc, T custom stlc_ty at level 0).

Notation " ||- T" := (wf_typ T) (at level 40, T custom stlc_ty at level 0).

Notation "t '>->' t'" := (target_step t t') (at level 40).


(*********************** Locally nameless related defns ***********************)

(* redefine gather_atoms for pick fresh *)
Ltac gather_atoms ::= (* for type var *)
  let A := gather_atoms_with (fun x : atoms => x) in
  let B := gather_atoms_with (fun x : atom => singleton x) in
  let C:= gather_atoms_with (fun x : exp => fv_exp x) in
  let D := gather_atoms_with (fun x : texp => fv_texp x) in
  let E := gather_atoms_with (fun x : tvl => fv_tvl x) in
  let F := gather_atoms_with (fun x : list (var * typ) => dom x) in
  let G := gather_atoms_with (fun x : list (var * ttyp) => dom x) in
  let H := gather_atoms_with (fun x : ctx => dom x) in
  let H' := gather_atoms_with (fun x : tctx => dom x) in
  constr:(A `union` B `union` C `union` D `union` E `union` F `union` G  `union` H `union` H').


Ltac solve_by_inverts n :=
  match goal with | H : ?T |- _ =>
  match type of T with Prop =>
    solve [
      inversion H;
      match n with S (S (?n')) => subst; solve_by_inverts (S n') end ]
  end end.

Ltac solve_by_invert :=
  solve_by_inverts 1.

Lemma wf_rcd_lookup : forall i T Ti,
  wf_typ T ->
  Tlookup i T = Some Ti ->
  wf_typ Ti.
Proof.
  introv WF LK.
  gen i Ti.
  induction WF; intros; simpl in LK; inverts LK.
  case_if*.
  - inverts* H1.
Qed.

Lemma rcd_typ_concat : forall T1 T2 T3,
    rec_typ T1 -> rec_typ T2 ->
    concat_typ T1 T2 T3 ->
    rec_typ T3.
Proof.
  introv WF1 WF2 CT.
  induction* CT.
  - inverts* WF1.
Qed.

Lemma wf_rcd_concat : forall T1 T2 T3,
    wf_typ T1 -> wf_typ T2 ->
    rec_typ T1 -> rec_typ T2 ->
    concat_typ T1 T2 T3 ->
    wf_typ T3.
Proof with eauto using rcd_typ_concat.
  introv WF1 WF2 RT1 RT2 CT.
  induction* CT.
  - inverts* WF1. inverts* RT1...
Qed.

Lemma target_typing_wf : forall G t T,
   target_typing G t T -> wf_typ T.
Proof with eauto.
  intros Ga t T Htyp.
  induction Htyp...
  all: pick fresh x...
  - (* T_App *)
    inversion IHHtyp1...
  - (* T_Proj *)
    eapply wf_rcd_lookup...
  - applys* wf_rcd_concat At Bt Ct.
Qed.

Lemma target_typing_lc_texp : forall G t T,
    target_typing G t T -> lc_texp t.
Proof with eauto.
  intros Ga t T Htyp.
  induction Htyp...
  all: pick fresh x...
Qed.

Lemma lookup_field_in_value : forall v T i Ti,
  value v ->
  target_typing [] v T ->
  Tlookup i T = Some Ti ->
  exists ti, tlookup i v = Some ti /\ target_typing [] ti Ti.
Proof with try solve_by_invert.
  introv Val Typ LK.
  induction Typ; try solve_by_invert.
  - simpl in LK. simpl.
    case_if; inverts LK; subst*.
    + forwards~ : IHTyp2.
      inverts~ Val.
Qed.

Theorem progress : forall t T,
     target_typing [] t T ->
     value t \/ exists t', t >-> t'.
Proof with try solve_by_invert.
  introv Typ.
  inductions Typ...
  all: try solve [left*].
  all: try solve [right*].
  - (* abs *)
    left. eauto using target_typing_lc_texp.
  - (* fixpoint *)
    right. exists*. eauto using target_typing_lc_texp.
  - (* application *)
    forwards~ [?|(?&?)]: IHTyp1.
    2: { right; exists*.
         applys TS_AppL; eauto using target_typing_lc_texp. }
    forwards~ [?|(?&?)]: IHTyp2.
    2: { right; exists; eauto using target_typing_lc_texp. }
    inverts Typ1...
    { right; exists; eauto using target_typing_lc_texp. }
  - (* cons *)
    forwards~ [?|(?&?)]: IHTyp1; forwards~ [?|(?&?)]: IHTyp2.
    all: right; exists; eauto using target_typing_lc_texp.
  - (* proj *)
    forwards~ [?|(?&?)]: IHTyp.
    2: right; exists; eauto using target_typing_lc_texp.
    + forwards* (?&?&?): lookup_field_in_value Typ.
  - (* concat *)
    forwards~ [?|(?&?)]: IHTyp1; forwards~ [?|(?&?)]: IHTyp2.
    2-4: right; exists; eauto using target_typing_lc_texp.
    inverts Typ1...
    2: inverts H2.
    all: right; exists; eauto using target_typing_lc_texp.
Qed.

Lemma weakening : forall G E F t T,
    target_typing (E ++ G) t T ->
    uniq (E ++ F ++ G) ->
    target_typing (E ++ F ++ G) t T.
Proof.
  introv Typ; gen F;
    inductions Typ; introv Ok; autos*.
    + (* abs *)
      pick fresh x and apply TTyping_Abs; eauto.
      rewrite_env (([(x, At)] ++ E) ++ F ++ G).
      apply~ H1.
      solve_uniq.
    + (* fix *)
      pick fresh x and apply TTyping_Fix.
      rewrite_env (([(x, At)] ++ E) ++ F ++ G).
      apply~ H0.
      solve_uniq.
Qed.

Lemma weakening_empty : forall G t T,
    uniq G -> target_typing [] t T -> target_typing G t T.
Proof.
  introv Uni Typ.
  rewrite_env ([]++G++[]).
  applys* weakening.
Qed.


Notation "[ z ~>> u ] e" := (subst_texp u z e) (at level 0).

Lemma substitution_preserves_typing : forall (E F : tctx) t u S T (z : atom),
    target_typing (F ++ [(z,S)] ++ E) t T ->
    target_typing E u S ->
    target_typing (F ++ E) ([z ~>> u] t) T.
Proof.
  introv Typ1 Typ2.
  induction t; inverts* Typ1.
  - simpl. case_if; subst.
    forwards* : binds_mid_eq H3.
    (* solve_uniq. *)
    (* binds_remove_mid *)
    (* destruct (Atom.eq_dec z x). *)
    (* + subst. simpl. Print binds_remove_eq. *)
Abort.

Theorem preservation : forall t t' T,
    target_typing [] t T ->
    t >-> t' ->
    target_typing [] t' T.
