;; Consent Management Contract
;; This contract tracks user permissions for data sharing

(define-data-var admin principal tx-sender)

;; Data structure for consent records
(define-map consent-records
  { user: principal, data-requester: principal, data-type: uint }
  {
    granted: bool,
    grant-date: uint,
    expiration-date: uint
  }
)

;; Grant consent for data sharing
(define-public (grant-consent (data-requester principal) (data-type uint) (expiration-date uint))
  (begin
    (asserts! (>= expiration-date block-height) (err u103))
    (ok (map-set consent-records
      { user: tx-sender, data-requester: data-requester, data-type: data-type }
      {
        granted: true,
        grant-date: block-height,
        expiration-date: expiration-date
      }
    ))
  )
)

;; Revoke consent for data sharing
(define-public (revoke-consent (data-requester principal) (data-type uint))
  (ok (map-set consent-records
    { user: tx-sender, data-requester: data-requester, data-type: data-type }
    {
      granted: false,
      grant-date: u0,
      expiration-date: u0
    }
  ))
)

;; Check if consent is granted
(define-read-only (has-consent (user principal) (data-requester principal) (data-type uint))
  (let ((consent (default-to
        { granted: false, grant-date: u0, expiration-date: u0 }
        (map-get? consent-records { user: user, data-requester: data-requester, data-type: data-type }))))
    (and (get granted consent) (>= (get expiration-date consent) block-height))
  )
)

;; Get all consent details
(define-read-only (get-consent-details (user principal) (data-requester principal) (data-type uint))
  (map-get? consent-records { user: user, data-requester: data-requester, data-type: data-type })
)

;; Data types reference (for documentation)
;; u1: Basic profile information
;; u2: Contact information
;; u3: Financial history
;; u4: Transaction history
;; u5: Credit score

