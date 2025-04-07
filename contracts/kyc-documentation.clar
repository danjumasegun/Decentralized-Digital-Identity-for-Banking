;; KYC Documentation Contract
;; This contract securely stores required identification records

(define-data-var admin principal tx-sender)

;; Data structure for KYC documents
(define-map kyc-documents
  { user: principal }
  {
    document-hash: (buff 32),
    document-type: uint,
    submission-date: uint,
    expiration-date: uint,
    status: uint  ;; 0: pending, 1: approved, 2: rejected, 3: expired
  }
)

;; Map of authorized KYC processors
(define-map kyc-processors
  { processor: principal }
  { authorized: bool }
)

;; Add a KYC processor (admin only)
(define-public (add-kyc-processor (processor principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (ok (map-set kyc-processors { processor: processor } { authorized: true }))
  )
)

;; Remove a KYC processor (admin only)
(define-public (remove-kyc-processor (processor principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (ok (map-set kyc-processors { processor: processor } { authorized: false }))
  )
)

;; Submit KYC document (user function)
(define-public (submit-kyc-document (document-hash (buff 32)) (document-type uint) (expiration-date uint))
  (ok (map-set kyc-documents
    { user: tx-sender }
    {
      document-hash: document-hash,
      document-type: document-type,
      submission-date: block-height,
      expiration-date: expiration-date,
      status: u0  ;; pending
    }
  ))
)

;; Update KYC document status (only callable by authorized processors)
(define-public (update-kyc-status (user principal) (status uint))
  (let ((processor-status (default-to { authorized: false } (map-get? kyc-processors { processor: tx-sender }))))
    (begin
      (asserts! (get authorized processor-status) (err u101))
      (asserts! (< status u4) (err u102))  ;; Status must be valid
      (let ((document (default-to
            { document-hash: 0x, document-type: u0, submission-date: u0, expiration-date: u0, status: u0 }
            (map-get? kyc-documents { user: user }))))
        (ok (map-set kyc-documents
          { user: user }
          {
            document-hash: (get document-hash document),
            document-type: (get document-type document),
            submission-date: (get submission-date document),
            expiration-date: (get expiration-date document),
            status: status
          }
        ))
      )
    )
  )
)

;; Check if KYC is approved for a user
(define-read-only (is-kyc-approved (user principal))
  (let ((document (default-to
        { document-hash: 0x, document-type: u0, submission-date: u0, expiration-date: u0, status: u0 }
        (map-get? kyc-documents { user: user }))))
    (and (is-eq (get status document) u1) (> (get expiration-date document) block-height))
  )
)

;; Get KYC document info
(define-read-only (get-kyc-info (user principal))
  (map-get? kyc-documents { user: user })
)

;; Transfer admin rights (admin only)
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (ok (var-set admin new-admin))
  )
)

