;; title: token-template
;; version: 1.0.0
;; summary: SIP-010 Fungible Token Template for StacksMint
;; description:
;;   A fully compliant SIP-010 fungible token base contract.
;;   Fork this contract and customize the constants below to deploy
;;   your own token on the Stacks blockchain.
;;   Also includes counter utility functions (increment / decrement).

;; =============================================================
;;  TRAITS
;; =============================================================

;; SIP-010 Fungible Token Standard (mainnet canonical contract as requirement in Clarinet.toml)
(impl-trait 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE.sip-010-trait-ft-standard.sip-010-trait)

;; =============================================================
;;  CONSTANTS  -- customize these before deploying
;; =============================================================

(define-constant token-name "My Token")
(define-constant token-symbol "MTK")
(define-constant token-decimals u6)
;; 1,000,000 tokens with 6 decimal places
(define-constant initial-supply u1000000000000)
(define-constant token-uri (some u"https://example.com/token-metadata.json"))

;; The principal that deployed this contract becomes the owner
(define-constant contract-owner tx-sender)

;; =============================================================
;;  ERROR CODES
;; =============================================================

(define-constant ERR-NOT-AUTHORIZED     (err u100))
(define-constant ERR-NOT-TOKEN-OWNER    (err u101))
(define-constant ERR-INVALID-AMOUNT     (err u103))
(define-constant ERR-NOT-MINTABLE       (err u104))
(define-constant ERR-COUNTER-UNDERFLOW  (err u105))

;; =============================================================
;;  DATA VARS
;; =============================================================

;; Controls whether new tokens can be minted after initial supply
(define-data-var mintable bool false)

;; General-purpose counter (utility -- not part of token logic)
(define-data-var utility-counter uint u0)

;; =============================================================
;;  TOKEN DEFINITION
;; =============================================================

(define-fungible-token stacksmint-token)

;; =============================================================
;;  INITIALIZATION  -- mint initial supply to deployer
;; =============================================================

(ft-mint? stacksmint-token initial-supply contract-owner)

;; =============================================================
;;  SIP-010 REQUIRED FUNCTIONS
;; =============================================================

;; Transfer tokens from sender to recipient.
;; The caller must be the token sender.
(define-public (transfer
    (amount uint)
    (sender principal)
    (recipient principal)
    (memo (optional (buff 34))))
  (begin
    (asserts! (is-eq tx-sender sender) ERR-NOT-TOKEN-OWNER)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (try! (ft-transfer? stacksmint-token amount sender recipient))
    (match memo m (begin (print m) true) true)
    (ok true)))

;; Return the token name
(define-read-only (get-name)
  (ok token-name))

;; Return the token ticker symbol
(define-read-only (get-symbol)
  (ok token-symbol))

;; Return the number of decimal places
(define-read-only (get-decimals)
  (ok token-decimals))

;; Return the token balance for a given principal
(define-read-only (get-balance (account principal))
  (ok (ft-get-balance stacksmint-token account)))

;; Return the current total supply
(define-read-only (get-total-supply)
  (ok (ft-get-supply stacksmint-token)))

;; Return the optional token URI (off-chain metadata)
(define-read-only (get-token-uri)
  (ok token-uri))

;; =============================================================
;;  OWNER-ONLY FUNCTIONS
;; =============================================================

;; Mint additional tokens to a recipient (only if mintable flag is set)
(define-public (mint (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (var-get mintable) ERR-NOT-MINTABLE)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (ft-mint? stacksmint-token amount recipient)))

;; Burn tokens from a sender (caller must own the tokens)
(define-public (burn (amount uint) (sender principal))
  (begin
    (asserts! (is-eq tx-sender sender) ERR-NOT-TOKEN-OWNER)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (ft-burn? stacksmint-token amount sender)))

;; Enable or disable future minting (owner only)
(define-public (set-mintable (enabled bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
    (ok (var-set mintable enabled))))

;; =============================================================
;;  READ-ONLY HELPERS
;; =============================================================

;; Returns true if additional minting is currently enabled
(define-read-only (is-mintable)
  (ok (var-get mintable)))

;; Returns the contract owner principal
(define-read-only (get-owner)
  (ok contract-owner))

;; =============================================================
;;  UTILITY -- COUNTER  (increment / decrement)
;;  These are standalone utility functions, independent of the
;;  token logic above. Useful for testing, tracking, or
;;  any general-purpose counting need.
;; =============================================================

;; Increment the utility counter by 1
(define-public (increment)
  (begin
    (var-set utility-counter (+ (var-get utility-counter) u1))
    (ok (var-get utility-counter))))

;; Decrement the utility counter by 1.
;; Reverts with ERR-COUNTER-UNDERFLOW if the counter is already 0.
(define-public (decrement)
  (begin
    (asserts! (> (var-get utility-counter) u0) ERR-COUNTER-UNDERFLOW)
    (var-set utility-counter (- (var-get utility-counter) u1))
    (ok (var-get utility-counter))))

;; Return the current value of the utility counter
(define-read-only (get-counter)
  (ok (var-get utility-counter)))
