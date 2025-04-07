;; Fraud Prevention Contract
;; This contract identifies suspicious patterns and activities

(define-data-var admin principal tx-sender)

;; Data structure for risk scores
(define-map risk-scores
  { user: principal }
  {
    score: uint,  ;; 0-100, higher means higher risk
    last-updated: uint,
    flagged: bool
  }
)

;; Map of authorized risk assessors
(define-map risk-assessors
  { assessor: principal }
  { authorized: bool }
)

;; Add a risk assessor (admin only)
(define-public (add-risk-assessor (assessor principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (ok (map-set risk-assessors { assessor: assessor } { authorized: true }))
  )
)

;; Remove a risk assessor (admin only)
(define-public (remove-risk-assessor (assessor principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (ok (map-set risk-assessors { assessor: assessor } { authorized: false }))
  )
)

;; Update risk score (only callable by authorized assessors)
(define-public (update-risk-score (user principal) (score uint))
  (let ((assessor-status (default-to { authorized: false } (map-get? risk-assessors { assessor: tx-sender }))))
    (begin
      (asserts! (get authorized assessor-status) (err u101))
      (asserts! (<= score u100) (err u102))  ;; Score must be between 0 and 100
      (ok (map-set risk-scores
        { user: user }
        {
          score: score,
          last-updated: block-height,
          flagged: (> score u75)  ;; Flag if score is above 75
        }
      ))
    )
  )
)

;; Report suspicious activity (can be called by any user)
(define-public (report-suspicious-activity (suspect principal) (activity-type uint) (evidence (buff 64)))
  (begin
    ;; Log the report (in a real implementation, this would trigger further investigation)
    (print { reporter: tx-sender, suspect: suspect, activity-type: activity-type, evidence: evidence })
    (ok true)
  )
)

;; Check if a user is flagged for fraud
(define-read-only (is-flagged (user principal))
  (let ((risk-info (default-to
        { score: u0, last-updated: u0, flagged: false }
        (map-get? risk-scores { user: user }))))
    (get flagged risk-info)
  )
)

;; Get risk score for a user
(define-read-only (get-risk-score (user principal))
  (let ((risk-info (default-to
        { score: u0, last-updated: u0, flagged: false }
        (map-get? risk-scores { user: user }))))
    (get score risk-info)
  )
)

;; Transfer admin rights (admin only)
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (ok (var-set admin new-admin))
  )
)

