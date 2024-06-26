Require Import LibTactics.
Require Import Metalib.Metatheory.
Require Import List. Import ListNotations.
Require Import Arith Lia.
Require Import Strings.String.
Require Import Sorting.Permutation.
Require Import Sorting.Sorted.
Require Export Translation.
Require Export TargetTypeSafety.

(* Type safety *)
(** The key is to prove the lookup label does exists in the record *)
(** To prove type safety, we need to translate typing contexts / types *)

#[local] Hint Resolve target_typing_wf_1 target_typing_wf_2 ttyp_trans_wf : core.
#[local] Hint Unfold Tlookup : core.

Fixpoint context_trans (G:ctx) : tctx :=
  match G with
  | nil => nil
  | (x, A) :: l => (x, |[A]|) :: (context_trans l)
  end.

Notation "||[ G ]||" := (context_trans G) (at level 1, G at next level).


Lemma elaboration_wf_ctx : forall G,
    uniq G  -> wf_ctx ||[G]||.
Proof with eauto using ttyp_trans_wf.
  introv HU. induction* G.
  simpl... destruct a... econstructor...
  inverts~ HU.
  Qed.

Open Scope list.

Lemma comerge_split : forall t1 A1 t B t2 A2,
    comerge t1 A1 B t2 A2 t -> spl B A1 A2.
Proof.
  introv HC. induction* HC; pick fresh x; forwards: H2 x.
  all: eauto.
Qed.

Lemma comerge_toplike_l : forall t1 A1 t B t2 A2,
    comerge t1 A1 B t2 A2 t -> toplike B -> toplike A1.
Proof.
  introv HC HT. applys split_toplike_l HT. applys* comerge_split.
Qed.

Lemma comerge_toplike_r : forall t1 A1 t B t2 A2,
    comerge t1 A1 B t2 A2 t -> toplike B -> toplike A2.
Proof.
  introv HC HT. applys split_toplike_r HT. applys* comerge_split.
Qed.

Lemma comerge_well_typed : forall E t1 A1 t B t2 A2 T1 T2,
    comerge t1 A1 B t2 A2 t ->
    target_typing E t1 T1 -> subTarget T1 |[A1]| -> subTarget |[A1]| T1 ->
    target_typing E t2 T2 -> subTarget T2 |[A2]| -> subTarget |[A2]| T2 ->
    exists T, target_typing E t T /\ subTarget T |[B]| /\ subTarget |[B]| T.
Proof with elia; try tassumption;
intuition eauto using target_typing_wf_1, target_typing_wf_2,
  target_typing_wf_typ, ST_refl, ST_trans, ST_toplike, ST_top,
  translate_to_record_types, subTarget_rec_typ, ttyp_trans_wf.

  introv HC HTa Eqa Eqa' HTb Eqb Eqb'. gen E t1 t2 t B T1 T2.
  indTypSize (size_typ A1 + size_typ A2). inverts HC.
  - exists. splits;
    try rewrite ttyp_trans_ord_top; try rewrite* <- check_toplike_sound_complete...
  - forwards (?&?&?): ST_concat Eqa' Eqb'.
    applys* concat_source_intersection...
    1-4: auto... intuition eauto using target_typing_wf_typ.
    exists. split.
    applys* TTyping_RcdMerge HTa HTb.
    all: eauto...
  - (* abs *)
    lets (?&?&?): lookup_ST_sub (|| typ_arrow A B1 ||) Eqa. simpl. case_if*.
    { rewrite* <- check_toplike_sound_complete in C. contradiction. }
    lets (?&?&?): lookup_ST_sub (|| typ_arrow A B1 ||) Eqa'. eassumption.
    lets (?&?&?): lookup_ST_sub (|| typ_arrow A B2 ||) Eqb. simpl; case_if*.
    { rewrite* <- check_toplike_sound_complete in C. contradiction. }
    lets (?&?&?): lookup_ST_sub (|| typ_arrow A B2 ||) Eqb'. eassumption.
    forwards* (?&?&?&?&?&?&?): ST_arrow_inv H3. subst*.
    forwards* (?&?&?&?&?&?&?): ST_arrow_inv H7. subst*.

    pick fresh y. lets Hc: H1 y.
    lets (?&?&?): IH ( ( y, |[ A ]| ) :: E) Hc. elia. now eauto.
    1,4: applys TTyping_App.
    3,6: split.
    1,7: applys TTyping_RcdProj.
    1,3: rewrite_env ( [ (y, |[ A ]|) ] ++  E); applys target_weakening_simpl; try eassumption.
    all: try eassumption.
    5,6: econstructor...
    all: auto...
    exists. split. applys* TTyping_RcdCons.
    pick fresh z and apply TTyping_Abs... forwards* : subst_var_typing.
    all: eauto. split...
    simpl. case_if*. now applys* ST_top_2. now applys* ST_rcd_2.
    simpl. case_if*. {
      exfalso. applys H. rewrite <- check_toplike_sound_complete in C.
      eauto using comerge_toplike_l.
    }
    now applys* ST_rcd_2.
  - (* abs *)
    lets (?&?&?): lookup_ST_sub (|| typ_arrow A B1 ||) Eqa. simpl. case_if*.
    { rewrite* <- check_toplike_sound_complete in C. contradiction. }
    lets (?&?&?): lookup_ST_sub (|| typ_arrow A B1 ||) Eqa'. eassumption.
    forwards* (?&?&?&?&?&?&?): ST_arrow_inv H4. subst*.

    pick fresh y. lets Hc: H2 y.
    lets (?&?&?): IH ( ( y, |[ A ]| ) :: E) Hc. elia. now eauto.
    1: applys TTyping_App. 6: econstructor...
    3: split.
    1: applys TTyping_RcdProj.
    1: rewrite_env ( [ (y, |[ A ]|) ] ++  E); applys target_weakening_simpl; try eassumption.
    all: try eassumption.
    3: econstructor...
    all: auto...
    exists. split. applys* TTyping_RcdCons.
    pick fresh z and apply TTyping_Abs... forwards* : subst_var_typing.
    all: eauto. split.
    simpl. case_if*. now applys* ST_top_2. now applys* ST_rcd_2.
    simpl. case_if*. {
      exfalso. applys H0. rewrite <- check_toplike_sound_complete in C.
      eauto using comerge_toplike_l.
    }
    now applys* ST_rcd_2.
  - (* abs *)
    lets (?&?&?): lookup_ST_sub (|| typ_arrow A B2 ||) Eqb. simpl; case_if*.
    { rewrite* <- check_toplike_sound_complete in C. contradiction. }
    lets (?&?&?): lookup_ST_sub (|| typ_arrow A B2 ||) Eqb'. eassumption.
    forwards* (?&?&?&?&?&?&?): ST_arrow_inv H4. subst*.

    pick fresh y. lets Hc: H2 y.
    lets (?&?&?): IH ( ( y, |[ A ]| ) :: E) Hc. elia. now eauto.
    4: applys TTyping_App. 1: econstructor...
    5: split.
    3: applys TTyping_RcdProj.
    3: rewrite_env ( [ (y, |[ A ]|) ] ++  E); applys target_weakening_simpl; try eassumption.
    all: try eassumption.
    5: econstructor...
    all: auto...
    exists. split. applys* TTyping_RcdCons.
    pick fresh z and apply TTyping_Abs... forwards* : subst_var_typing.
    all: eauto. split.
    simpl. case_if*. {
      exfalso. applys H1. rewrite <- check_toplike_sound_complete in C.
      eauto using comerge_toplike_r.
    }
    now applys* ST_rcd_2.
    simpl. case_if*.  {
      exfalso. applys H1. rewrite <- check_toplike_sound_complete in C.
      eauto using comerge_toplike_r.
    } now applys* ST_rcd_2.
  - (* rcd *)
    assert (Tlookup (|| typ_rcd l0 A0 ||) |[ (typ_rcd l0 A0) ]| = Some |[A0]|).
    { simpl. case_if*.
      - rewrite* <- check_toplike_sound_complete in C. contradiction.
    }
    lets* (?&?&?): lookup_ST_sub (|| typ_rcd l0 A0 ||) Eqa.
    lets* (?&?&?): lookup_ST_sub (|| typ_rcd l0 A0 ||) Eqa'. unify_lookup.
    assert (Tlookup (|| typ_rcd l0 A3 ||) |[ (typ_rcd l0 A3) ]| = Some |[A3]|).
    { simpl. case_if*.
      - rewrite* <- check_toplike_sound_complete in C. contradiction.
    }
    lets* (?&?&?): lookup_ST_sub (|| typ_rcd l0 A3 ||) Eqb.
    lets* (?&?&?): lookup_ST_sub (|| typ_rcd l0 A3 ||) Eqb'. unify_lookup.

    lets (?&?&?&?): IH E H1. elia. econstructor...
    3: econstructor... 1-4 : auto...
    exists. splits. applys* TTyping_RcdCons...
    simpl. case_if*. now applys* ST_top_2. now applys* ST_rcd_2.
    simpl. case_if*. {
      exfalso. applys H. rewrite <- check_toplike_sound_complete in C.
      eauto using comerge_toplike_l.
    }
    now applys* ST_rcd_2.
  - (* rcd *)
    assert (Tlookup (|| typ_rcd l0 A0 ||) |[ (typ_rcd l0 A0) ]| = Some |[A0]|).
    { simpl. case_if*.
      - rewrite* <- check_toplike_sound_complete in C. contradiction.
    }
    lets* (?&?&?): lookup_ST_sub (|| typ_rcd l0 A0 ||) Eqa.
    lets* (?&?&?): lookup_ST_sub (|| typ_rcd l0 A0 ||) Eqa'. unify_lookup.

    lets (?&?&?&?): IH E H2. elia. econstructor...
    3: econstructor... 1-4 : auto...
    exists. splits. applys* TTyping_RcdCons...
    simpl. case_if*. now applys* ST_top_2. now applys* ST_rcd_2.
    simpl. case_if*. {
      exfalso. applys H0. rewrite <- check_toplike_sound_complete in C.
      eauto using comerge_toplike_l.
    }
    now applys* ST_rcd_2.
  - (* rcd *)
    assert (Tlookup (|| typ_rcd l0 A3 ||) |[ (typ_rcd l0 A3) ]| = Some |[A3]|).
    { simpl. case_if*.
      - rewrite* <- check_toplike_sound_complete in C. contradiction.
    }
    lets* (?&?&?): lookup_ST_sub (|| typ_rcd l0 A3 ||) Eqb.
    lets* (?&?&?): lookup_ST_sub (|| typ_rcd l0 A3 ||) Eqb'. unify_lookup.

    lets (?&?&?&?): IH E H2. elia. econstructor...
    3: econstructor... 1-4 : auto...
    exists. splits. applys* TTyping_RcdCons...
    simpl. case_if*. now applys* ST_top_2. now applys* ST_rcd_2.
    simpl. case_if*. {
      exfalso. applys H1. rewrite <- check_toplike_sound_complete in C.
      eauto using comerge_toplike_r.
    }
    now applys* ST_rcd_2.
    Unshelve. all: eauto.
Qed.

Lemma check_toplike_false : forall B,
    ~ toplike B -> check_toplike B = false.
Proof.
  introv TL. remember (check_toplike B). destruct* b.
  exfalso. applys TL. rewrite* check_toplike_sound_complete.
Qed.

#[local] Hint Resolve check_toplike_false : core.

Lemma split_toplike : forall A B C,
    spl A B C -> toplike B -> toplike C -> toplike A.
Proof.
  introv HS HT1 HT2.
  induction* HS.
  all: inverts HT1; inverts* HT2.
Qed.

Lemma cosub_not_toplike : forall t1 t2 A B,
    cosub t1 A B t2 -> ~ toplike B -> ~ toplike A.
Proof.
  introv HC HT HTA. applys HT. clear HT. gen t1 t2.
  indTypSize (size_typ A + size_typ B).
  inverts HC. 1-7: inverts~ HTA.
  - pick fresh x; try lets (?&?): H1 x; intuition eauto.
    forwards*: IH H4. elia.
  - forwards*: IH H1. elia.
  - forwards*: IH H0. elia.
  - forwards*: IH H0. elia.
  - forwards*: IH H0. elia. forwards*: IH H1. elia.
    eauto using split_toplike.
Qed.

Lemma cosub_well_typed : forall E t1 A B t2 At,
    cosub t1 A B t2 -> target_typing E t1 At -> subTarget At |[A]| ->
    exists Bt', target_typing E t2 Bt' /\ subTarget Bt' |[B]| /\ subTarget |[B]| Bt'.
Proof with elia; try tassumption;
intuition eauto using target_typing_wf_1, target_typing_wf_2,
  target_typing_wf_typ, ST_refl, ST_trans, ST_toplike, ST_top, ST_rcd_2,
  cosub_not_toplike,
  translate_to_record_types, subTarget_rec_typ.

  introv HS HT ST. gen At t1 t2 E.
  indTypSize (size_typ A + size_typ B). inverts HS.
  - (* top *)
    forwards* EQ: ttyp_trans_ord_top B. rewrite* <- check_toplike_sound_complete.
    exists. split...
  - (* bot *)
    lets* (?&EQ&WF): ttyp_trans_ord_ntop B. rewrite EQ...
    exists. splits. applys TTyping_RcdCons.
    5: applys ST_refl. 2: right.
    all: eauto.
    pick fresh y and apply TTyping_Fix.
    unfold open_texp_wrt_texp. simpl. applys TTyping_Var... split; applys~ ST_refl.
  - (* base *)
    rewrite ttyp_trans_base...
    lets (?&?&?&?): lookup_ST_sub (|| typ_base ||) ST. simpl. reflexivity.
    exists. splits.
    applys TTyping_RcdCons. 3: applys TTyping_RcdProj H0.
    4: econstructor...
    all: eauto...
  - (* arrow *)
    pick fresh y.
    lets* (HS1 & HS2): H1 y.

    lets (?&?&Eq): lookup_ST_sub (|| (typ_arrow A1 A2) ||) ST.
    (* lets* (?&?&?&?&?): flex_typing_property3 (|| (typ_arrow A1 A2) ||) HT. *)
    rewrite ttyp_trans_ord_ntop_arrow. 2: eauto. simpl. case_if...
    applys check_toplike_false. applys* cosub_not_toplike.

    forwards (?&?&?&?&?&?&?): ST_arrow_inv Eq. subst.

    lets (?&?&?): IH HS1 ((y, |[ B1 ]|) :: E)...
    { econstructor... }
    lets (?&?&?): IH HS2. elia.
    2: { (* applys flex_typing_property0... *)
      applys TTyping_App.
      rewrite_env ([ (y, |[ B1 ]|) ] ++ E).
      applys TTyping_RcdProj H2.
      applys target_weakening_simpl...
      tassumption.
      split...
    }
    auto...
    exists. splits. applys TTyping_RcdCons.
    4: econstructor...
      3: {
        pick fresh z and apply TTyping_Abs.
        forwards* : subst_var_typing H8.
        solve_notin.
      }
      3: eauto.
      2: right*.
      1: now eauto.
      rewrite ttyp_trans_ord_ntop_arrow...
    simpl. case_if*. {
      exfalso. applys H0. rewrite <- check_toplike_sound_complete in C.
      eauto using comerge_toplike_r.
    }
    now applys* ST_rcd_2.
  - (* rcd *)
    lets (?&?&Eq&?): lookup_ST_sub (|| typ_rcd l0 A0 ||) ST.
    simpl. case_if*.
    { forwards*: cosub_not_toplike H1.
      apply check_toplike_sound_complete in C. contradiction. }

    forwards* (?&?&?): IH H1 E...
    exists. splits.
    applys* TTyping_RcdCons...

    simpl. case_if*. {
      exfalso. applys H0. rewrite <- check_toplike_sound_complete in C.
      eauto using comerge_toplike_r.
    }
    now applys* ST_rcd_2.

    simpl. case_if*. {
      exfalso. applys H0. rewrite <- check_toplike_sound_complete in C.
      eauto using comerge_toplike_r.
    }
    now applys* ST_rcd_2.
  - (* and *)
    applys* IH H0 HT...
    applys* ST_trans ST_andl.
  - (* and *)
    applys* IH H0 HT... applys* ST_trans ST_andr.
  - (* comerge *)
    forwards* (?&?&Eq1&?): IH H0. elia.
    forwards* (?&?&Eq2&?): IH H1. elia.
    forwards(?&?&?): comerge_well_typed H2; try eassumption.
    exists. split*...
    Unshelve. all: econstructor.
Qed.

Lemma ctx_trans_preserves_binds : forall x A G,
    binds x A G -> binds x |[A]| ||[G]||.
Proof.
  introv HB.
  induction* G.
  inverts HB.
  - applys in_eq.
  - destruct a. simpl. right.
    applys* IHG.
Qed.

Lemma ctx_trans_preserves_dom : forall G,
    dom ||[G]|| = dom G.
Proof.
  introv. induction* G. destruct a.
  simpl. rewrite* IHG.
Qed.

Lemma ctx_trans_preserves_uniq : forall G,
    uniq G -> uniq ||[G]||.
Proof.
  introv HU.
  induction HU; simpl; constructor*.
  rewrite* ctx_trans_preserves_dom.
Qed.

Lemma toplike_appdist_inv : forall A C T t1 t2 t3,
    distapp t1 A t2 T t3 C -> toplike A -> toplike C.
Proof.
  introv HA HT. inductions HA.
  all: inverts* HT.
Qed.

Lemma toplike_appdist_inv_2 : forall A C T t1 t2 t3,
    distapp t1 A t2 T t3 C -> toplike C -> toplike A.
Proof.
  introv HA HT. inductions HA.
  all: inverts* HT.
Qed.

Lemma distapp_well_typed_app : forall A B C G t1 t2 t3 A' B',
    distapp t1 A t2 B t3 C ->
    target_typing ||[ G ]|| t1 A' -> subTarget A' |[A]| ->
    target_typing ||[ G ]|| t2 B' -> subTarget B' |[B]| ->
    exists C', target_typing ||[ G ]|| t3 C' /\ subTarget C' |[C]| /\ subTarget |[C]| C'.
Proof with intuition eauto using target_typing_wf_1, target_typing_wf_2,
  target_typing_wf_typ, ST_refl, ST_trans, ST_toplike, ST_top, ST_rcd_2,
  cosub_not_toplike, ttyp_trans_wf,
  translate_to_record_types, subTarget_rec_typ.

  introv HA HTa HEa HTb HEb. gen A' B'.
  inductions HA; intros.
  - rewrite* ttyp_trans_ord_top.
  - forwards* (?&?&?): cosub_well_typed H1.
    lets (?&?&?&?): lookup_ST_sub (|| (typ_arrow A B) ||) HEa.
     simpl. case_if*.
    { apply check_toplike_sound_complete in C0. contradiction. }
    forwards(?&?&?&?&?&?&?): ST_arrow_inv H5. subst.
    exists. splits. applys TTyping_App.
    econstructor. 1-3: now eauto. all: try split...
  - forwards* (?&?&?&?): IHHA1 HTb. eauto using ST_refl, ST_trans, ST_andl.
    forwards* (?&?&?&?): IHHA2 HTb. eauto using ST_refl, ST_trans, ST_andr.
    forwards*: concat_source_intersection...
    forwards* (?&?&?&?): ST_concat H5 H1 H3...
    exists. split. applys* TTyping_RcdMerge H H2.
    all: eauto...
Qed.


Lemma distapp_well_typed_proj : forall A l t1 t3 C G A',
    proj t1 A l t3 C -> target_typing ||[ G ]|| t1 A' ->
    subTarget A' |[A]| ->
    exists C', target_typing ||[ G ]|| t3 C' /\ subTarget C' |[C]| /\ subTarget |[C]| C'.
Proof with intuition eauto using target_typing_wf_1, target_typing_wf_2,
  target_typing_wf_typ, ST_refl, ST_trans, ST_toplike, ST_top, ST_rcd_2,
  cosub_not_toplike,
    translate_to_record_types, subTarget_rec_typ.

  introv HA HT HS. gen A'.
  inductions HA; intros...
  - rewrite* ttyp_trans_ord_top.
  - lets (?&?&?): lookup_ST_sub (|| typ_rcd l A ||) HS.
    simpl. case_if*.
    { apply check_toplike_sound_complete in C. contradiction. }
    exists. split. applys* TTyping_RcdProj. now eauto.
  - rewrite* ttyp_trans_ord_top.
  - forwards* (?&?&?): IHHA1 HT; eauto using ST_refl, ST_trans, ST_andl.
    forwards* (?&?&?): IHHA2 HT; eauto using ST_refl, ST_trans, ST_andr.
    forwards*: concat_source_intersection...
    forwards* (?&?&?&?): ST_concat H3 H4 H0...
    exists. split. applys* TTyping_RcdMerge H H1.
    all: eauto...
Qed.

Theorem elaboration_well_typed : forall G e dirflag A t,
    elaboration G e dirflag A t ->
    exists A', target_typing ||[ G ]|| t A' /\  subTarget A' |[A]| /\  subTarget |[A]| A'.
Proof with intuition eauto using target_typing_wf_1, target_typing_wf_2,
  target_typing_wf_typ, ST_refl, ST_trans, ST_toplike, ST_top, ST_rcd_2,
  cosub_not_toplike, ctx_trans_preserves_uniq, ttyp_trans_wf,
    translate_to_record_types, subTarget_rec_typ,  elaboration_wf_ctx.
  introv HT.
  induction HT...
  - rewrite* ttyp_trans_ord_top.
    exists. splits. applys TTyping_RcdNil... all: eauto using ST_refl...
  - rewrite* ttyp_trans_ord_top.
    exists. split. applys TTyping_RcdNil... all: eauto using ST_refl...
    rewrite* <- check_toplike_sound_complete.
  - rewrite* ttyp_trans_ord_top. rewrite* <- check_toplike_sound_complete.
  - (* base *)
    rewrite* ttyp_trans_base.
    exists. split. applys TTyping_RcdCons.
    4: eauto...
    all: eauto...
  - (* var *)
    apply ctx_trans_preserves_binds in H0...
    exists. split*. econstructor...
  - (* fix *)
    pick fresh x. forwards~ (?&?&?): H0 x.
    exists. split. remember ||[ G ]||. pick fresh y and apply TTyping_Fix.
    applys subst_var_typing H1.
    all: eauto...
  - (* abs *)
    pick fresh x. forwards~ (?&?&?&?): H1 x.
    forwards: target_typing_wf_2 H2. inverts H5.
    forwards: target_typing_wf_1 H2. inverts H5.
    rewrite ttyp_trans_ord_ntop_arrow...
    exists. split. applys TTyping_RcdCons.
    4: eauto...
    3: { remember ||[ G ]||.
         pick fresh y and apply TTyping_Abs.
         applys subst_var_typing H2.
         all: eauto.
    }
    3: econstructor.
    all: eauto...
  - (* app *)
    destruct_conj. applys* distapp_well_typed_app...
  - (* rcd *)
    rewrite ttyp_trans_rcd.
    destruct_conj. exists. split. applys* TTyping_RcdCons.
    splits. all: eauto...
  - (* proj *)
    destruct_conj. applys* distapp_well_typed_proj.
  - (* merge *)
    destruct_conj.
    lets HC: concat_source_intersection A B...
    forwards* (?&?&?): ST_concat HC...
    exists. split.
    applys TTyping_RcdMerge H3 H0...
    split...
  - (* subsumption *)
    destruct_conj. forwards* (?&?&?&?): cosub_well_typed H.
    Unshelve. all: econstructor.
Qed.
