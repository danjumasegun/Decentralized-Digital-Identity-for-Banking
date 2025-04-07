;; Identity Verification Contract
;; This contract validates user information through trusted sources

(define-data-var admin principal tx-sender)

;; Data structure for identity verification status
(define-map identity-verification
  { user: principal }
  {
    verified: bool,
    verification-date: uint,
    verifier: principal,
    verification-level: uint
  }
)

;; List of trusted verifiers
(define-map trusted-verifiers
  { verifier: principal }
  { active: bool }
)

;; Add a trusted verifier (admin only)
(define-public (add-trusted-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (ok (map-set trusted-verifiers { verifier: verifier } { active: true }))
  )
)

;; Remove a trusted verifier (admin only)
(define-public (remove-trusted-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (ok (map-set trusted-verifiers { verifier: verifier } { active: false }))
  )
)

;; Verify a user's identity (only callable by trusted verifiers)
(define-public (verify-identity (user principal) (verification-level uint))
  (let ((verifier-status (default-to { active: false } (map-get? trusted-verifiers { verifier: tx-sender }))))
    (begin
      (asserts! (get active verifier-status) (err u101))
      (ok (map-set identity-verification
        { user: user }
        {
          verified: true,
          verification-date: block-height,
          verifier: tx-sender,
          verification-level: verification-level
        }
      ))
    )
  )
)

;; Check if a user is verified
(define-read-only (is-verified (user principal))
  (let ((verification-info (default-to
        { verified: false, verification-date: u0, verifier: tx-sender, verification-level: u0 }
        (map-get? identity-verification { user: user }))))
    (get verified verification-info)
  )
)

;; Get verification level of a user
(define-read-only (get-verification-level (user principal))
  (let ((verification-info (default-to
        { verified: false, verification-date: u0, verifier: tx-sender, verification-level: u0 }
        (map-get? identity-verification { user: user }))))
    (get verification-level verification-info)
  )
)

;; Transfer admin rights (admin only)
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (ok (var-set admin new-admin))
  )
)

