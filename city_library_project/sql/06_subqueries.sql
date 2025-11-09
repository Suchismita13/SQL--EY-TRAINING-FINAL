
-- Query 6.1: Members with Above-Average Fines
SELECT
    M.first_name,
    M.last_name,
    SUM(F.fine_amount) AS total_unpaid_fines,
    COUNT(F.fine_id) AS number_of_fines
FROM
    members M
JOIN
    loans L ON M.member_id = L.member_id
JOIN
    fines F ON L.loan_id = F.loan_id
WHERE
    F.paid = FALSE
GROUP BY
    M.member_id, M.first_name, M.last_name
HAVING
    SUM(F.fine_amount) > (
        -- Subquery: Calculates the average unpaid fine amount across ALL loans
        SELECT AVG(fine_amount) FROM fines WHERE paid = FALSE
    )
ORDER BY
    total_unpaid_fines DESC;

-- -------------------------------------------------------------------

-- Query 6.2: Books More Popular Than Average
SELECT
    B.title,
    A.author_name,
    COUNT(L.loan_id) AS total_loans,
    (
        -- Subquery: Calculates the overall average loans per distinct book_id
        SELECT AVG(loan_count) FROM (
            SELECT COUNT(L2.loan_id) AS loan_count
            FROM loans L2
            JOIN book_copies BC2 ON L2.copy_id = BC2.copy_id
            GROUP BY BC2.book_id
        ) AS avg_loans_per_book
    ) AS overall_avg_loans
FROM
    books B
JOIN
    authors A ON B.author_id = A.author_id
JOIN
    book_copies BC ON B.book_id = BC.book_id
JOIN
    loans L ON BC.copy_id = L.copy_id
GROUP BY
    B.book_id, B.title, A.author_name
HAVING
    total_loans > overall_avg_loans
ORDER BY
    total_loans DESC;

-- -------------------------------------------------------------------

-- Query 6.3: CTE - Member Borrowing Summary
WITH loan_counts AS (
    SELECT member_id, COUNT(loan_id) AS total_loans
    FROM loans
    GROUP BY member_id
),
fine_totals AS (
    SELECT L.member_id, COALESCE(SUM(F.fine_amount), 0.00) AS total_fines
    FROM fines F
    JOIN loans L ON F.loan_id = L.loan_id
    WHERE F.paid = FALSE
    GROUP BY L.member_id
),
active_counts AS (
    SELECT member_id, COUNT(loan_id) AS active_loans
    FROM loans
    WHERE status = 'active'
    GROUP BY member_id
)
SELECT
    M.first_name,
    M.last_name,
    COALESCE(LC.total_loans, 0) AS total_loans,
    COALESCE(AC.active_loans, 0) AS active_loans,
    COALESCE(FT.total_fines, 0.00) AS total_unpaid_fines,
    M.status AS member_status
FROM
    members M
LEFT JOIN loan_counts LC ON M.member_id = LC.member_id
LEFT JOIN fine_totals FT ON M.member_id = FT.member_id
LEFT JOIN active_counts AC ON M.member_id = AC.member_id
ORDER BY
    total_loans DESC;

-- -------------------------------------------------------------------

-- Query 6.4: Find Books Never Loaned (Subquery Method)
SELECT
    B.title,
    A.author_name,
    B.genre,
    B.total_copies
FROM
    books B
JOIN
    authors A ON B.author_id = A.author_id
WHERE
    B.book_id NOT IN (
        -- Subquery: Finds all book_ids that have been loaned at least once
        SELECT DISTINCT BC.book_id
        FROM loans L
        JOIN book_copies BC ON L.copy_id = BC.copy_id
    )
ORDER BY
    B.publication_year ASC;

-- -------------------------------------------------------------------

-- Query 6.5: Members Who Attended All Book Club Events
SELECT
    M.first_name,
    M.last_name,
    COUNT(ER.registration_id) AS events_attended
FROM
    members M
JOIN
    event_registrations ER ON M.member_id = ER.member_id
JOIN
    events E ON ER.event_id = E.event_id
WHERE
    E.event_type = 'book_club'
GROUP BY
    M.member_id, M.first_name, M.last_name
HAVING
    COUNT(ER.registration_id) = (
        -- Subquery: Finds the total count of 'book_club' events
        SELECT COUNT(event_id) FROM events WHERE event_type = 'book_club'
    )
ORDER BY
    M.last_name, M.first_name;

-- -------------------------------------------------------------------

-- Query 6.6: CTE - Monthly Revenue Report
WITH fine_revenue AS (
    SELECT
        DATE_FORMAT(payment_date, '%Y-%m') AS year_month,
        SUM(fine_amount) AS fine_revenue
    FROM fines
    WHERE paid = TRUE AND payment_date IS NOT NULL
    GROUP BY year_month
),
membership_revenue AS (
    -- Placeholder: Estimates new membership revenue for simplicity
    SELECT
        DATE_FORMAT(join_date, '%Y-%m') AS year_month,
        COUNT(member_id) * 10.00 AS membership_revenue
    FROM members
    GROUP BY year_month
)
SELECT
    COALESCE(FR.year_month, MR.year_month) AS year_month,
    COALESCE(FR.fine_revenue, 0.00) AS fine_revenue,
    COALESCE(MR.membership_revenue, 0.00) AS membership_revenue,
    COALESCE(FR.fine_revenue, 0.00) + COALESCE(MR.membership_revenue, 0.00) AS total_revenue
FROM
    fine_revenue FR
LEFT JOIN membership_revenue MR ON FR.year_month = MR.year_month
UNION
SELECT
    COALESCE(FR.year_month, MR.year_month) AS year_month,
    COALESCE(FR.fine_revenue, 0.00) AS fine_revenue,
    COALESCE(MR.membership_revenue, 0.00) AS membership_revenue,
    COALESCE(FR.fine_revenue, 0.00) + COALESCE(MR.membership_revenue, 0.00) AS total_revenue
FROM
    membership_revenue MR
LEFT JOIN fine_revenue FR ON MR.year_month = FR.year_month
ORDER BY
    year_month DESC
LIMIT 12;

-- -------------------------------------------------------------------

-- Query 6.7: Correlated Subquery - Loan History
SELECT
    B.title,
    A.author_name,
    B.genre,
    (
        -- Correlated Subquery: Finds the MAX loan_date for the current book (B.book_id)
        SELECT MAX(L.loan_date)
        FROM loans L
        JOIN book_copies BC ON L.copy_id = BC.copy_id
        WHERE BC.book_id = B.book_id
    ) AS most_recent_loan_date
FROM
    books B
JOIN
    authors A ON B.author_id = A.author_id
WHERE
    B.book_id IN (
        -- Ensures only books that have been loaned at least once are included
        SELECT DISTINCT BC_Sub.book_id
        FROM loans L_Sub
        JOIN book_copies BC_Sub ON L_Sub.copy_id = BC_Sub.copy_id
    )
ORDER BY
    most_recent_loan_date DESC;

-- -------------------------------------------------------------------

-- Query 6.8: CTE - Book Recommendation Engine (Concept)
WITH member_favorite_genre AS (
    -- CTE 1: Determine each member's most borrowed genre
    SELECT
        L.member_id,
        B.genre,
        ROW_NUMBER() OVER(PARTITION BY L.member_id ORDER BY COUNT(B.genre) DESC) AS rn
    FROM loans L
    JOIN book_copies BC ON L.copy_id = BC.copy_id
    JOIN books B ON BC.book_id = B.book_id
    GROUP BY L.member_id, B.genre
),
recommended_books AS (
    -- CTE 2: Find the most popular book in each genre
    SELECT
        B.title AS recommended_title,
        B.genre,
        B.book_id
    FROM books B
    JOIN book_copies BC ON B.book_id = BC.book_id
    LEFT JOIN loans L ON BC.copy_id = L.copy_id
    GROUP BY B.book_id, B.title, B.genre
    ORDER BY COUNT(L.loan_id) DESC
    LIMIT 100
)
SELECT
    M.first_name,
    M.last_name,
    MFG.genre AS favorite_genre,
    RB.recommended_title
FROM
    members M
JOIN
    member_favorite_genre MFG ON M.member_id = MFG.member_id AND MFG.rn = 1
JOIN
    recommended_books RB ON MFG.genre = RB.genre
WHERE
    RB.book_id NOT IN (
        -- Exclude books the member has already borrowed
        SELECT BC_Sub.book_id
        FROM loans L_Sub
        JOIN book_copies BC_Sub ON L_Sub.copy_id = BC_Sub.copy_id
        WHERE L_Sub.member_id = M.member_id
    )
LIMIT 10;