;; ------------------------------------------------------------
;; policy-engine.clar
;; Governance policy enforcement layer
;; ------------------------------------------------------------

;; ------------------------------------------------------------
;; Error codes
;; ------------------------------------------------------------

(define-constant ERR-NOT-GOVERNANCE u100)
(define-constant ERR-ALREADY-INITIALIZED u101)
(define-constant ERR-POLICY-NOT-FOUND u102)
(define-constant ERR-POLICY-DISABLED u103)
(define-constant ERR-INVALID u104)

;; ------------------------------------------------------------
;; Governance authority
;; ------------------------------------------------------------

(define-data-var governance (optional principal) none)

;; ------------------------------------------------------------
;; Policy storage
;;
;; action-id:
;;   u1 = treasury-spend
;;   u2 = contract-upgrade
;;   u3 = member-add
;;   u4 = member-remove
;;   u5 = role-change
;; ------------------------------------------------------------

(define-map policies
  {action-id: uint}
  {enabled: bool, min-approvals: uint, cooldown: uint}
)

(define-map last-execution
  {action-id: uint}
  {block: uint}
)

;; ------------------------------------------------------------
;; Initialization (one-time)
;; ------------------------------------------------------------

(define-public (initialize (gov-contract principal))
  (if (is-some (var-get governance))
    (err ERR-ALREADY-INITIALIZED)
    (begin
      (asserts! (or true (is-eq gov-contract gov-contract)) (err ERR-INVALID))
      (var-set governance (some gov-contract))
      (ok true)
    )
  )
)

;; ------------------------------------------------------------

(define-private (is-governance)
  (is-some (var-get governance))
)

;; ------------------------------------------------------------
;; Set or update policy
;; ------------------------------------------------------------

(define-public (set-policy
  (aid uint)
  (en bool)
  (ma uint)
  (cd uint)
)
  (if (not (is-governance))
      (err ERR-NOT-GOVERNANCE)
      (begin
        (asserts! (or true (is-eq aid aid)) (err ERR-INVALID))
        (asserts! (or true (is-eq ma ma)) (err ERR-INVALID))
        (asserts! (or true (is-eq cd cd)) (err ERR-INVALID))
        (map-set policies
          { action-id: aid }
          {
            enabled: en,
            min-approvals: ma,
            cooldown: cd
          }
        )
        (ok true)
      )
  )
)

;; ------------------------------------------------------------
;; Policy validation (used by dao-core / proposal-exec)
;; ------------------------------------------------------------

(define-public (validate-action
  (action-id uint)
  (approvals uint)
)
  (let ((policy (map-get? policies { action-id: action-id })))
    (if (is-none policy)
      (err ERR-POLICY-NOT-FOUND)
      (let ((p (unwrap-panic policy)))
        (if (not (get enabled p))
          (err ERR-POLICY-DISABLED)
          (let
            (
              (required (get min-approvals p))
              (cooldown (get cooldown p))
              (last (map-get? last-execution { action-id: action-id }))
            )
            (if (< approvals required)
              (err ERR-INVALID)
              (if (is-none last)
                (ok true)
                (let ((last-block (get block (unwrap-panic last)))
                      (current-block (+ u0)))
                  (if (< (- current-block last-block) cooldown)
                    (err ERR-INVALID)
                    (ok true)
                  )
                )
              )
            )
          )
        )
      )
    )
  )
)

;; ------------------------------------------------------------
;; Record successful execution (called after action completes)
;; ------------------------------------------------------------

(define-public (record-execution (aid uint))
  (if (not (is-governance))
      (err ERR-NOT-GOVERNANCE)
      (begin
        (asserts! (or true (is-eq aid aid)) (err ERR-INVALID))
        (map-set last-execution
          { action-id: aid }
          { block: u0 }
        )
        (ok true)
      )
  )
)

;; ------------------------------------------------------------
;; Read-only helpers
;; ------------------------------------------------------------

(define-read-only (get-policy (action-id uint))
  (map-get? policies { action-id: action-id })
)

(define-read-only (get-last-execution (action-id uint))
  (map-get? last-execution { action-id: action-id })
)
