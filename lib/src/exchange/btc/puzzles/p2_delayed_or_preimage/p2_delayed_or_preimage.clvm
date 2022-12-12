;; This puzzle is like `p2_delegated_puzzle_or_hidden_puzzle` except it allows for
;; TWO public keys with different restrictions. There is a "clawback" key and a
;; "sweep" key.
;;
;; The "clawback" key is only valid after a timeout of `CLAWBACK_DELAY_SECONDS`, using
;; the `ASSERT_SECONDS_RELATIVE` condition.
;;
;; The "sweep" public key has a corresponding secret `sweep_preimage`, committed to by
;; `SWEEP_RECEIPT_HASH`. To use this key, the `sweep_preimage` must be revealed.
;;
;; With this puzzle, two parties can do an atomic swap based on a pre-image reveal in a
;; trustless way. Revealing the pre-image releases the XCH coin to the sweep public key.

(mod ((CLAWBACK_DELAY_SECONDS . CLAWBACK_PUBKEY) (SWEEP_RECEIPT_HASH . SWEEP_PUBKEY) sweep_preimage p2_dpohp_solution)
  ; set sweep_preimage to 0 to do clawback case
  ;
  ; p2_dpohp_solution = "pay to delegated puzzle or hidden puzzle" solution
  ;  That is, treat the activated `PUBKEY` as a synthetic key used in `p2_delegated_puzzle_or_hidden_puzzle`.
  ;  This allows all the graftroot and taproot features to be used here.

  ; This is the compiled standard `p2_delegated_puzzle_or_hidden_puzzle`
  (defconstant P2_DELEGATED_PUZZLE_OR_HIDDEN_PUZZLE (a (q 2 (i 11 (q 2 (i (= 5 (point_add 11 (pubkey_for_exp (sha256 11 (a 6 (c 2 (c 23 ()))))))) (q 2 23 47) (q 8)) 1) (q 4 (c 4 (c 5 (c (a 6 (c 2 (c 23 ()))) ()))) (a 23 47))) 1) (c (q 50 2 (i (l 5) (q 11 (q . 2) (a 6 (c 2 (c 9 ()))) (a 6 (c 2 (c 13 ())))) (q 11 (q . 1) 5)) 1) 1)))

  (defconstant ASSERT_SECONDS_RELATIVE 80)

  (defmacro assert items
      (if (r items)
          (list if (f items) (c assert (r items)) (q (x)))
          (f items)
      )
  )

  (defun-inline clawback (CLAWBACK_DELAY_SECONDS CLAWBACK_PUBKEY p2_dpohp_solution)
    (c (list ASSERT_SECONDS_RELATIVE CLAWBACK_DELAY_SECONDS) (a P2_DELEGATED_PUZZLE_OR_HIDDEN_PUZZLE (c CLAWBACK_PUBKEY p2_dpohp_solution)))
  )

  (defun-inline sweep (SWEEP_RECEIPT_HASH SWEEP_PUBKEY sweep_preimage p2_dpohp_solution)
    (assert (= (sha256 sweep_preimage) SWEEP_RECEIPT_HASH)
      (a P2_DELEGATED_PUZZLE_OR_HIDDEN_PUZZLE (c SWEEP_PUBKEY p2_dpohp_solution))
    )
  )

  ; look at `sweep_preimage` to determine if we are in the "sweep" or "clawback" case
  ; if `sweep_preimage` is 0, then we are in the clawback case
  (if sweep_preimage
    (sweep SWEEP_RECEIPT_HASH SWEEP_PUBKEY sweep_preimage p2_dpohp_solution)
    (clawback CLAWBACK_DELAY_SECONDS CLAWBACK_PUBKEY p2_dpohp_solution)
  )
)
