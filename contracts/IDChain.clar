;; title: IDChain
;; version: 1.0
;; summary: Decentralized Student Identity System
;; description: A blockchain-based student ID system for campus access, event registration, and verification

(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-STUDENT-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-REGISTERED (err u102))
(define-constant ERR-INVALID-STATUS (err u103))
(define-constant ERR-ACCESS-DENIED (err u104))
(define-constant ERR-EVENT-NOT-FOUND (err u105))
(define-constant ERR-ALREADY-REGISTERED-EVENT (err u106))
(define-constant ERR-EVENT-FULL (err u107))
(define-constant ERR-INVALID-DEPARTMENT (err u108))
(define-constant ERR-CREDENTIAL-NOT-FOUND (err u109))
(define-constant ERR-ALREADY-AWARDED (err u110))
(define-constant ERR-CREDENTIAL-REVOKED (err u111))

(define-data-var contract-owner principal tx-sender)
(define-data-var student-counter uint u0)
(define-data-var event-counter uint u0)
(define-data-var credential-counter uint u0)

(define-map students
  { student-id: uint }
  {
    wallet: principal,
    name: (string-ascii 64),
    email: (string-ascii 128),
    student-number: (string-ascii 32),
    department: (string-ascii 32),
    year: uint,
    gpa: uint,
    status: (string-ascii 16),
    registration-block: uint,
    last-updated: uint
  }
)

(define-map student-wallets
  { wallet: principal }
  { student-id: uint }
)

(define-map campus-events
  { event-id: uint }
  {
    name: (string-ascii 64),
    description: (string-ascii 256),
    organizer: principal,
    max-capacity: uint,
    current-attendance: uint,
    event-date: uint,
    location: (string-ascii 64),
    requires-verification: bool,
    status: (string-ascii 16)
  }
)

(define-map event-registrations
  { event-id: uint, student-id: uint }
  {
    registration-block: uint,
    attendance-confirmed: bool
  }
)

(define-map access-permissions
  { student-id: uint, resource: (string-ascii 32) }
  {
    granted: bool,
    granted-by: principal,
    expiry-block: uint
  }
)

(define-map department-admins
  { department: (string-ascii 32) }
  { admin: principal }
)

(define-map credentials
  { credential-id: uint }
  {
    student-id: uint,
    credential-type: (string-ascii 32),
    title: (string-ascii 128),
    description: (string-ascii 256),
    issuer: principal,
    issue-date: uint,
    expiry-date: uint,
    metadata: (string-ascii 256),
    revoked: bool,
    revoked-reason: (string-ascii 128)
  }
)

(define-map student-credentials
  { student-id: uint, credential-type: (string-ascii 32) }
  { credential-count: uint }
)

(define-public (register-student 
  (name (string-ascii 64))
  (email (string-ascii 128))
  (student-number (string-ascii 32))
  (department (string-ascii 32))
  (year uint)
)
  (let 
    (
      (new-student-id (+ (var-get student-counter) u1))
    )
    (asserts! (is-none (map-get? student-wallets { wallet: tx-sender })) ERR-ALREADY-REGISTERED)
    (map-set students
      { student-id: new-student-id }
      {
        wallet: tx-sender,
        name: name,
        email: email,
        student-number: student-number,
        department: department,
        year: year,
        gpa: u0,
        status: "active",
        registration-block: stacks-block-height,
        last-updated: stacks-block-height
      }
    )
    (map-set student-wallets
      { wallet: tx-sender }
      { student-id: new-student-id }
    )
    (var-set student-counter new-student-id)
    (ok new-student-id)
  )
)

(define-public (update-student-status (student-id uint) (new-status (string-ascii 16)))
  (let 
    (
      (student-data (unwrap! (map-get? students { student-id: student-id }) ERR-STUDENT-NOT-FOUND))
      (caller-student-id (get student-id (default-to { student-id: u0 } (map-get? student-wallets { wallet: tx-sender }))))
    )
    (asserts! (or 
      (is-eq tx-sender (var-get contract-owner))
      (is-eq tx-sender (get wallet student-data))
      (is-eq tx-sender (default-to tx-sender (get admin (map-get? department-admins { department: (get department student-data) }))))
    ) ERR-UNAUTHORIZED)
    (map-set students
      { student-id: student-id }
      (merge student-data { status: new-status, last-updated: stacks-block-height })
    )
    (ok true)
  )
)

(define-public (update-gpa (student-id uint) (new-gpa uint))
  (let 
    (
      (student-data (unwrap! (map-get? students { student-id: student-id }) ERR-STUDENT-NOT-FOUND))
    )
    (asserts! (or 
      (is-eq tx-sender (var-get contract-owner))
      (is-eq tx-sender (default-to tx-sender (get admin (map-get? department-admins { department: (get department student-data) }))))
    ) ERR-UNAUTHORIZED)
    (map-set students
      { student-id: student-id }
      (merge student-data { gpa: new-gpa, last-updated: stacks-block-height })
    )
    (ok true)
  )
)

(define-public (create-event
  (name (string-ascii 64))
  (description (string-ascii 256))
  (max-capacity uint)
  (event-date uint)
  (location (string-ascii 64))
  (requires-verification bool)
)
  (let 
    (
      (new-event-id (+ (var-get event-counter) u1))
    )
    (map-set campus-events
      { event-id: new-event-id }
      {
        name: name,
        description: description,
        organizer: tx-sender,
        max-capacity: max-capacity,
        current-attendance: u0,
        event-date: event-date,
        location: location,
        requires-verification: requires-verification,
        status: "active"
      }
    )
    (var-set event-counter new-event-id)
    (ok new-event-id)
  )
)

(define-public (register-for-event (event-id uint))
  (let 
    (
      (student-id (get student-id (unwrap! (map-get? student-wallets { wallet: tx-sender }) ERR-UNAUTHORIZED)))
      (student-data (unwrap! (map-get? students { student-id: student-id }) ERR-STUDENT-NOT-FOUND))
      (event-data (unwrap! (map-get? campus-events { event-id: event-id }) ERR-EVENT-NOT-FOUND))
    )
    (asserts! (is-eq (get status student-data) "active") ERR-INVALID-STATUS)
    (asserts! (is-none (map-get? event-registrations { event-id: event-id, student-id: student-id })) ERR-ALREADY-REGISTERED-EVENT)
    (asserts! (< (get current-attendance event-data) (get max-capacity event-data)) ERR-EVENT-FULL)
    (map-set event-registrations
      { event-id: event-id, student-id: student-id }
      {
        registration-block: stacks-block-height,
        attendance-confirmed: false
      }
    )
    (map-set campus-events
      { event-id: event-id }
      (merge event-data { current-attendance: (+ (get current-attendance event-data) u1) })
    )
    (ok true)
  )
)

(define-public (confirm-attendance (event-id uint) (student-id uint))
  (let 
    (
      (event-data (unwrap! (map-get? campus-events { event-id: event-id }) ERR-EVENT-NOT-FOUND))
      (registration-data (unwrap! (map-get? event-registrations { event-id: event-id, student-id: student-id }) ERR-STUDENT-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get organizer event-data)) ERR-UNAUTHORIZED)
    (map-set event-registrations
      { event-id: event-id, student-id: student-id }
      (merge registration-data { attendance-confirmed: true })
    )
    (ok true)
  )
)

(define-public (grant-access (student-id uint) (resource (string-ascii 32)) (expiry-blocks uint))
  (let 
    (
      (student-data (unwrap! (map-get? students { student-id: student-id }) ERR-STUDENT-NOT-FOUND))
      (expiry-block (+ stacks-block-height expiry-blocks))
    )
    (asserts! (or 
      (is-eq tx-sender (var-get contract-owner))
      (is-eq tx-sender (default-to tx-sender (get admin (map-get? department-admins { department: (get department student-data) }))))
    ) ERR-UNAUTHORIZED)
    (asserts! (is-eq (get status student-data) "active") ERR-INVALID-STATUS)
    (map-set access-permissions
      { student-id: student-id, resource: resource }
      {
        granted: true,
        granted-by: tx-sender,
        expiry-block: expiry-block
      }
    )
    (ok true)
  )
)

(define-public (revoke-access (student-id uint) (resource (string-ascii 32)))
  (let 
    (
      (student-data (unwrap! (map-get? students { student-id: student-id }) ERR-STUDENT-NOT-FOUND))
      (access-data (unwrap! (map-get? access-permissions { student-id: student-id, resource: resource }) ERR-ACCESS-DENIED))
    )
    (asserts! (or 
      (is-eq tx-sender (var-get contract-owner))
      (is-eq tx-sender (get granted-by access-data))
      (is-eq tx-sender (default-to tx-sender (get admin (map-get? department-admins { department: (get department student-data) }))))
    ) ERR-UNAUTHORIZED)
    (map-set access-permissions
      { student-id: student-id, resource: resource }
      (merge access-data { granted: false })
    )
    (ok true)
  )
)

(define-public (set-department-admin (department (string-ascii 32)) (admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED)
    (map-set department-admins
      { department: department }
      { admin: admin }
    )
    (ok true)
  )
)

(define-read-only (get-student-info (student-id uint))
  (map-get? students { student-id: student-id })
)

(define-read-only (get-student-by-wallet (wallet principal))
  (match (map-get? student-wallets { wallet: wallet })
    student-record (map-get? students { student-id: (get student-id student-record) })
    none
  )
)

(define-read-only (get-event-info (event-id uint))
  (map-get? campus-events { event-id: event-id })
)

(define-read-only (is-registered-for-event (event-id uint) (student-id uint))
  (is-some (map-get? event-registrations { event-id: event-id, student-id: student-id }))
)

(define-read-only (has-access (student-id uint) (resource (string-ascii 32)))
  (match (map-get? access-permissions { student-id: student-id, resource: resource })
    access-data (and 
      (get granted access-data)
      (> (get expiry-block access-data) stacks-block-height)
    )
    false
  )
)

(define-read-only (verify-student (wallet principal))
  (let 
    (
      (student-record (map-get? student-wallets { wallet: wallet }))
    )
    (match student-record
      record (let 
        (
          (student-data (unwrap! (map-get? students { student-id: (get student-id record) }) (err false)))
        )
        (ok (and 
          (is-eq (get wallet student-data) wallet)
          (is-eq (get status student-data) "active")
        ))
      )
      (ok false)
    )
  )
)

(define-read-only (get-student-count)
  (var-get student-counter)
)

(define-read-only (get-event-count)
  (var-get event-counter)
)

(define-read-only (get-department-admin (department (string-ascii 32)))
  (map-get? department-admins { department: department })
)

(define-public (issue-credential
  (student-id uint)
  (credential-type (string-ascii 32))
  (title (string-ascii 128))
  (description (string-ascii 256))
  (expiry-blocks uint)
  (metadata (string-ascii 256))
)
  (let
    (
      (student-data (unwrap! (map-get? students { student-id: student-id }) ERR-STUDENT-NOT-FOUND))
      (new-credential-id (+ (var-get credential-counter) u1))
      (expiry-date (if (> expiry-blocks u0) (+ stacks-block-height expiry-blocks) u0))
      (current-count (default-to { credential-count: u0 } (map-get? student-credentials { student-id: student-id, credential-type: credential-type })))
    )
    (asserts! (or
      (is-eq tx-sender (var-get contract-owner))
      (is-eq tx-sender (default-to tx-sender (get admin (map-get? department-admins { department: (get department student-data) }))))
    ) ERR-UNAUTHORIZED)
    (asserts! (is-eq (get status student-data) "active") ERR-INVALID-STATUS)
    (map-set credentials
      { credential-id: new-credential-id }
      {
        student-id: student-id,
        credential-type: credential-type,
        title: title,
        description: description,
        issuer: tx-sender,
        issue-date: stacks-block-height,
        expiry-date: expiry-date,
        metadata: metadata,
        revoked: false,
        revoked-reason: ""
      }
    )
    (map-set student-credentials
      { student-id: student-id, credential-type: credential-type }
      { credential-count: (+ (get credential-count current-count) u1) }
    )
    (var-set credential-counter new-credential-id)
    (ok new-credential-id)
  )
)

(define-public (revoke-credential (credential-id uint) (reason (string-ascii 128)))
  (let
    (
      (credential-data (unwrap! (map-get? credentials { credential-id: credential-id }) ERR-CREDENTIAL-NOT-FOUND))
      (student-data (unwrap! (map-get? students { student-id: (get student-id credential-data) }) ERR-STUDENT-NOT-FOUND))
    )
    (asserts! (or
      (is-eq tx-sender (var-get contract-owner))
      (is-eq tx-sender (get issuer credential-data))
      (is-eq tx-sender (default-to tx-sender (get admin (map-get? department-admins { department: (get department student-data) }))))
    ) ERR-UNAUTHORIZED)
    (asserts! (not (get revoked credential-data)) ERR-CREDENTIAL-REVOKED)
    (map-set credentials
      { credential-id: credential-id }
      (merge credential-data { revoked: true, revoked-reason: reason })
    )
    (ok true)
  )
)

(define-read-only (get-credential (credential-id uint))
  (map-get? credentials { credential-id: credential-id })
)

(define-read-only (verify-credential (credential-id uint))
  (match (map-get? credentials { credential-id: credential-id })
    credential-data (ok (and
      (not (get revoked credential-data))
      (or
        (is-eq (get expiry-date credential-data) u0)
        (> (get expiry-date credential-data) stacks-block-height)
      )
    ))
    (err false)
  )
)

(define-read-only (get-student-credential-count (student-id uint) (credential-type (string-ascii 32)))
  (default-to { credential-count: u0 } (map-get? student-credentials { student-id: student-id, credential-type: credential-type }))
)

(define-read-only (get-total-credentials)
  (var-get credential-counter)
)
