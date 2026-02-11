;; xSTX Token Implementation
(define-fungible-token xstx)
(define-data-var current-height uint u0)

;; ----------------------------
;; Constants & Maps
;; ----------------------------
(define-constant MIN_STAKE u10000)
(define-map stakes {user: principal} {amount: uint, timestamp: uint})
(define-map proposals {id: uint} {creator: principal, description: (string-utf8 256), end-block: uint, votes-for: uint, votes-against: uint, executed: bool})
(define-map vote-records {proposal-id: uint, voter: principal} {vote: bool, weight: uint})
(define-map rewards {user: principal} uint)
(define-data-var reward-pool uint u0)
(define-data-var proposal-counter uint u0)
(define-data-var emergency-flag bool false)

;; ----------------------------
;; Stake STX and Mint xSTX
;; ----------------------------
(define-public (stake-stx (amount uint))
    (begin
        (asserts! (>= amount MIN_STAKE) (err u100))
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (map-set stakes {user: tx-sender} {amount: amount, timestamp: (var-get current-height)})
        (try! (ft-mint? xstx amount tx-sender))
        (ok amount)))

;; ----------------------------
;; Proposals & Governance
;; ----------------------------
(define-public (submit-proposal (desc (string-utf8 256)) (duration uint))
  (let 
    ((id (+ (var-get proposal-counter) u1))
     (cur-height (var-get current-height)))
    (begin
      (asserts! (> duration u0) (err u400))
      (var-set proposal-counter id)
      (map-set proposals 
        {id: id} 
        {
          creator: tx-sender,
          description: desc,
          end-block: (+ cur-height duration),
          votes-for: u0,
          votes-against: u0,
          executed: false
        })
      (ok id))))

(define-public (vote (id uint) (support bool))
  (let ((stake-data (map-get? stakes {user: tx-sender}))
        (proposal (map-get? proposals {id: id})))
    (match stake-data
      staked
        (match proposal
          proposal-val
            (let ((amount (get amount staked)))
              (asserts! (is-none (map-get? vote-records {proposal-id: id, voter: tx-sender})) (err u200))
              (if support
                (begin
                  (map-set proposals {id: id} (merge proposal-val {votes-for: (+ (get votes-for proposal-val) amount)}))
                  (map-set vote-records {proposal-id: id, voter: tx-sender} {vote: support, weight: amount})
                  (ok true))
                (begin
                  (map-set proposals {id: id} (merge proposal-val {votes-against: (+ (get votes-against proposal-val) amount)}))
                  (map-set vote-records {proposal-id: id, voter: tx-sender} {vote: support, weight: amount})
                  (ok true))))
          (err u404))
      (err u201))))

(define-public (execute-proposal (id uint))
  (let ((proposal (map-get? proposals {id: id})))
    (match proposal
      prop
        (begin
          (asserts! (>= u0 (get end-block prop)) (err u301))
          (asserts! (not (get executed prop)) (err u302))
          (asserts! (> (get votes-for prop) (get votes-against prop)) (err u303))
          (map-set proposals {id: id} (merge prop {executed: true}))
          (ok {result: "Proposal executed", id: id}))
      (err u404))))

;; ----------------------------
;; Reward Management
;; ----------------------------
(define-public (claim-rewards)
  (let ((amount (default-to u0 (map-get? rewards {user: tx-sender}))))
    (begin
      (asserts! (> amount u0) (err u500))
      (map-delete rewards {user: tx-sender})
      (try! (stx-transfer? amount (as-contract tx-sender) tx-sender))
      (ok true))))

(define-public (distribute-rewards)
  (let ((pool (var-get reward-pool)))
    (begin
      (asserts! (> pool u0) (err u510))
      (var-set reward-pool u0)
      (ok true))))

;; ----------------------------
;; Emergency Exit & Controls
;; ----------------------------
(define-public (trigger-emergency)
  (begin
    (asserts! (is-eq tx-sender contract-caller) (err u999))
    (var-set emergency-flag true)
    (ok true)))
(define-public (exit-stake)
  (begin
    (asserts! (var-get emergency-flag) (err u600))
    (let ((staked (map-get? stakes {user: tx-sender})))
      (match staked
        s
          (begin
            (map-delete stakes {user: tx-sender})
            (try! (ft-burn? xstx (get amount s) tx-sender))
            (try! (stx-transfer? (get amount s) (as-contract tx-sender) tx-sender))
            (ok true))
        (err u601)))))

;; ----------------------------
;; Additional Functions
;; ----------------------------
(define-public (get-user-stake (user principal))
  (ok (map-get? stakes {user: user})))

(define-public (get-proposal (id uint))
  (ok (map-get? proposals {id: id})))

(define-read-only (get-total-reward-pool)
  (ok (var-get reward-pool)))

(define-read-only (is-emergency)
  (ok (var-get emergency-flag)))
