-- Query 7.1: All People in the System
SELECT
    CONCAT(first_name, ' ', last_name) AS full_name,
    email,
    'Member' AS person_type
FROM
    members

UNION

SELECT
    author_name AS full_name,
    NULL AS email,
    'Author' AS person_type
FROM
    authors
    
ORDER BY
    person_type DESC, full_name ASC;

-- -------------------------------------------------------------------

-- Query 7.2: Comprehensive Activity Log
SELECT
    'Loan' AS activity_type,
    L.loan_date AS activity_date,
    CONCAT(M.first_name, ' ', M.last_name, ' loaned "', B.title, '"') AS description
FROM
    loans L
JOIN
    members M ON L.member_id = M.member_id
JOIN
    book_copies BC ON L.copy_id = BC.copy_id
JOIN
    books B ON BC.book_id = B.book_id

UNION ALL

SELECT
    'Event' AS activity_type,
    E.event_date AS activity_date,
    CONCAT('Event: ', E.event_name) AS description
FROM
    events E

UNION ALL

SELECT
    'Registration' AS activity_type,
    ER.registration_date AS activity_date,
    CONCAT(M.first_name, ' ', M.last_name, ' registered for "', E.event_name, '"') AS description
FROM
    event_registrations ER
JOIN
    members M ON ER.member_id = M.member_id
JOIN
    events E ON ER.event_id = E.event_id

ORDER BY
    activity_date DESC
LIMIT 50;

-- -------------------------------------------------------------------

-- Query 7.3: Books Available vs Currently Loaned
SELECT
    B.title,
    'On Loan' AS status,
    COUNT(DISTINCT L.loan_id) AS count
FROM
    books B
JOIN
    book_copies BC ON B.book_id = BC.book_id
JOIN
    loans L ON BC.copy_id = L.copy_id
WHERE
    L.status = 'active'
GROUP BY
    B.title

UNION

SELECT
    B.title,
    'Available' AS status,
    COUNT(BC.copy_id) - COALESCE(SUM(CASE WHEN L.status = 'active' THEN 1 ELSE 0 END), 0) AS count
FROM
    books B
JOIN
    book_copies BC ON B.book_id = BC.book_id
LEFT JOIN
    loans L ON BC.copy_id = L.copy_id
GROUP BY
    B.title
HAVING
    count > 0

ORDER BY
    title ASC;

-- -------------------------------------------------------------------

-- Query 7.4: Members with Issues
WITH OverdueMembers AS (
    SELECT DISTINCT member_id, 'Overdue Book' AS issue_type FROM loans WHERE due_date < CURDATE() AND status = 'active'
),
UnpaidFineMembers AS (
    SELECT DISTINCT L.member_id, 'Unpaid Fines' AS issue_type FROM fines F JOIN loans L ON F.loan_id = L.loan_id WHERE F.paid = FALSE
),
SuspendedMembers AS (
    SELECT member_id, 'Suspended Status' AS issue_type FROM members WHERE status = 'suspended'
)
SELECT
    M.first_name,
    M.last_name,
    M.email,
    I.issue_type,
    (
        SELECT COUNT(issue_type)
        FROM (
            SELECT member_id, 'Overdue Book' AS issue_type FROM OverdueMembers
            UNION SELECT member_id, 'Unpaid Fines' AS issue_type FROM UnpaidFineMembers
            UNION SELECT member_id, 'Suspended Status' AS issue_type FROM SuspendedMembers
        ) AS AllIssues
        WHERE AllIssues.member_id = M.member_id
    ) AS total_issues_count
FROM
    members M
JOIN
    (
        SELECT member_id, issue_type FROM OverdueMembers
        UNION SELECT member_id, issue_type FROM UnpaidFineMembers
        UNION SELECT member_id, issue_type FROM SuspendedMembers
    ) AS I ON M.member_id = I.member_id
ORDER BY
    M.last_name, M.first_name;

-- -------------------------------------------------------------------

-- Query 7.5: Popular vs Unpopular Books
WITH book_loans AS (
    SELECT
        B.book_id,
        B.title,
        A.author_name,
        COUNT(L.loan_id) AS loan_count
    FROM
        books B
    JOIN
        authors A ON B.author_id = A.author_id
    JOIN
        book_copies BC ON B.book_id = BC.book_id
    LEFT JOIN
        loans L ON BC.copy_id = L.copy_id
    GROUP BY
        B.book_id, B.title, A.author_name
),
PopularBooks AS (
    SELECT title, author_name, loan_count, 'Popular' AS category
    FROM book_loans
    ORDER BY loan_count DESC
    LIMIT 10
),
UnpopularBooks AS (
    SELECT title, author_name, loan_count, 'Unpopular' AS category
    FROM book_loans
    ORDER BY loan_count ASC
    LIMIT 10
)
SELECT * FROM PopularBooks
UNION ALL
SELECT * FROM UnpopularBooks
ORDER BY category DESC, loan_count DESC;