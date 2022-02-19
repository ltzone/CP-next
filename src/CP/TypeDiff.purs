module Language.CP.TypeDiff where

import Prelude

import Control.Alt ((<|>))
import Control.Monad.Maybe.Trans (MaybeT, lift, runMaybeT)
import Control.Plus (empty)
import Data.Maybe (Maybe(..))
import Data.Tuple.Nested ((/\))
import Language.CP.Context (Typing, lookupTyBind, throwTypeError)
import Language.CP.Subtyping (isTopLike, split)
import Language.CP.Syntax.Core (Ty(..), tySubst)
import Partial.Unsafe (unsafeCrashWith)

tyDiff :: Ty -> Ty -> Typing Ty
tyDiff m s = runMaybeT (diff m s) >>= case _ of
  Just d  -> pure d
  Nothing -> throwTypeError $ "cannot subtract " <> show s <> " from " <> show m
  -- this algorithm does not depend on subtyping or disjointness
  where diff :: Ty -> Ty -> MaybeT Typing Ty
        diff TyBot TyBot = pure TyTop
        diff t TyBot = diff t t
        diff TyBot _ = empty
        diff t1 t2 | isTopLike t1 || isTopLike t2 = pure t1
        diff t1 t2 | Just (t3 /\ t4) <- split t1 =
          tyMerge t1 <$> diff t3 t2 <*> diff t4 t2
        diff t@(TyArrow targ1 tret1 b) (TyArrow targ2 tret2 _) = do
          dret <- diff tret1 tret2
          if dret == tret1 then pure t  -- disjoint (m * s)
          else do darg <- diff targ2 targ1
                  if isTopLike darg  -- supertype (m :> s)
                  then pure $ TyArrow targ1 dret b else empty
        diff t@(TyRcd l1 t1 b) (TyRcd l2 t2 _)
          | l1 == l2  = TyRcd l1 <$> diff t1 t2 <@> b
          | otherwise = pure t
        diff t@(TyForall a1 td1 t1) (TyForall a2 td2 t2) = do
          d <- diff t1 t2'
          if d == t1 then pure t  -- disjoint (m * s)
          else do dd <- diff td2 td1
                  if isTopLike dd  -- supertype (m :> s)
                  then pure $ TyForall a1 td1 dd else empty
          where t2' = tySubst a2 (TyVar a1) t2
        diff (TyVar a1) (TyVar a2) | a1 == a2 = pure TyTop
        diff (TyVar a) t = lift (lookupTyBind a) >>= case _ of
          Just td -> do d <- diff t td       -- a * td ->
                        if isTopLike d       -- t :> td ->
                        then pure $ TyVar a  -- a * t
                        else empty
          Nothing -> empty
        diff t (TyVar a) = diff (TyVar a) t  -- only disjointness matters
        diff t (TyAnd t1 t2) = (diff t t1 >>= \t' -> diff t' t2) <|>
                               (diff t t2 >>= \t' -> diff t' t1)
        diff t1 t2 | t1 == t2  = pure TyTop
                   | otherwise = pure t1

tyMerge :: Ty -> Ty -> Ty -> Ty
tyMerge (TyAnd _ _) t1 t2 = TyAnd t1 t2
tyMerge (TyArrow targ tret b) (TyArrow _ t1 _) (TyArrow _ t2 _) =
  TyArrow targ (tyMerge tret t1 t2) b
tyMerge (TyRcd l t b) (TyRcd _ t1 _) (TyRcd _ t2 _) = TyRcd l (tyMerge t t1 t2) b
tyMerge (TyForall a td t) (TyForall _ _ t1) (TyForall _ _ t2) =
  TyForall a td (tyMerge t t1 t2)
tyMerge t t1 t2 = unsafeCrashWith $ "CP.TypeDiff.tyMerge: " <>
  "cannot merge " <> show t1 <> " and " <> show t2 <> " according to " <> show t