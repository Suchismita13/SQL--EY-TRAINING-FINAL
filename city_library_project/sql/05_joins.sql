-- Query 5.1: Complete Loan History with Details
SELECT
    M.first_name,
    M.last_name,
    M.email AS member_email,
    B.title AS book_title,
    A.author_name,
    L.loan_date,
    L.due_date,
    L.return_date,
    L.status
FROM
    loans L
JOIN
    members M ON L.member_id = M.member_id
JOIN
    book_copies BC ON L.copy_id = BC.copy_id
JOIN
    books B ON BC.book_id = B.book_id
JOIN
    authors A ON B.author_id = A.author_id
ORDER BY
    L.loan_date DESC
LIMIT 20;

-- -------------------------------------------------------------------

-- Query 5.2: Books Currently On Loan
SELECT
    B.title AS book_title,
    A.author_name,
    BC.copy_number,
    M.first_name,
    M.last_name AS borrower_name,
    L.loan_date,
    L.due_date,
    DATEDIFF(L.due_date, CURDATE()) AS days_until_due
FROM
    loans L
JOIN
    members M ON L.member_id = M.member_id
JOIN
    book_copies BC ON L.copy_id = BC.copy_id
JOIN
    books B ON BC.book_id = B.book_id
JOIN
    authors A ON B.author_id = A.author_id
WHERE
    L.status = 'active'
ORDER BY
    L.due_date ASC;

-- -------------------------------------------------------------------

-- Query 5.3: Members with Overdue Books and Fines
SELECT
    M.first_name,
    M.last_name,
    M.email,
    M.phone,
    COUNT(DISTINCT L.loan_id) AS number_of_overdue_books,
    COALESCE(SUM(F.fine_amount), 0.00) AS total_unpaid_fines
FROM
    members M
JOIN
    loans L ON M.member_id = L.member_id
LEFT JOIN
    fines F ON L.loan_id = F.loan_id
WHERE
    L.status = 'active'
    AND L.due_date < CURDATE()
    AND F.paid = FALSE
GROUP BY
    M.member_id, M.first_name, M.last_name, M.email, M.phone
ORDER BY
    total_unpaid_fines DESC;

-- -------------------------------------------------------------------

-- Query 5.4: Book Availability Report
SELECT
    B.title,
    A.author_name,
    B.total_copies,
    COUNT(L.loan_id) AS copies_on_loan,
    (B.total_copies - COUNT(L.loan_id)) AS available_copies
FROM
    books B
JOIN
    authors A ON B.author_id = A.author_id
LEFT JOIN
    book_copies BC ON B.book_id = BC.book_id
LEFT JOIN
    loans L ON BC.copy_id = L.copy_id AND L.status = 'active'
GROUP BY
    B.book_id, B.title, B.total_copies, A.author_name
ORDER BY
    available_copies ASC, B.title ASC;

-- -------------------------------------------------------------------

-- Query 5.5: Event Attendance List
SELECT
    E.event_name,
    E.event_date,
    M.first_name,
    M.last_name,
    M.email AS member_email,
    ER.registration_date
FROM
    events E
JOIN
    event_registrations ER ON E.event_id = ER.event_id
JOIN
    members M ON ER.member_id = M.member_id
WHERE
    E.event_date >= CURDATE()
ORDER BY
    E.event_date ASC,
    M.last_name ASC;

-- -------------------------------------------------------------------

-- Query 5.6: Author Popularity Report
SELECT
    A.author_name,
    COUNT(DISTINCT B.book_id) AS book_count,
    COUNT(L.loan_id) AS total_loans,
    ROUND(COUNT(L.loan_id) / COUNT(DISTINCT B.book_id), 2) AS avg_loans_per_book
FROM
    authors A
JOIN
    books B ON A.author_id = B.author_id
JOIN
    book_copies BC ON B.book_id = BC.book_id
JOIN
    loans L ON BC.copy_id = L.copy_id
GROUP BY
    A.author_id, A.author_name
HAVING
    COUNT(L.loan_id) >= 1
ORDER BY
    total_loans DESC
LIMIT 10;

-- -------------------------------------------------------------------

-- Query 5.7: Members Who Never Borrowed
SELECT
    M.first_name,
    M.last_name,
    M.email,
    M.join_date,
    M.membership_type
FROM
    members M
LEFT JOIN
    loans L ON M.member_id = L.member_id
WHERE
    L.loan_id IS NULL
ORDER BY
    M.join_date ASC;

-- -------------------------------------------------------------------

-- Query 5.8: Self-Join - Members from Same Address
SELECT
    m1.first_name AS member_1_first,
    m1.last_name AS member_1_last,
    m2.first_name AS member_2_first,
    m2.last_name AS member_2_last,
    m1.address AS shared_address
FROM
    members m1
INNER JOIN
    members m2 ON m1.address = m2.address
WHERE
    m1.member_id < m2.member_id
    AND m1.address IS NOT NULL
ORDER BY
    m1.address;