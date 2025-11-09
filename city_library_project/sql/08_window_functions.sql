-- Query 8.1: Rank Members by Borrowing Activity
SELECT
    ROW_NUMBER() OVER (ORDER BY COUNT(L.loan_id) DESC) AS row_num,
    RANK() OVER (ORDER BY COUNT(L.loan_id) DESC) AS rank_overall,
    DENSE_RANK() OVER (ORDER BY COUNT(L.loan_id) DESC) AS dense_rank_overall,
    M.first_name,
    M.last_name,
    COUNT(L.loan_id) AS total_loans
FROM
    members M
JOIN
    loans L ON M.member_id = L.member_id
GROUP BY
    M.member_id, M.first_name, M.last_name
ORDER BY
    total_loans DESC;
    
-- Query 8.2: Running Total of Fines Collected
SELECT
    payment_date,
    fine_amount,
    SUM(fine_amount) OVER (ORDER BY payment_date ASC) AS running_total_fines
FROM
    fines
WHERE
    paid = TRUE
ORDER BY
    payment_date ASC;

-- Query 8.3: Rank Books by Genre
WITH GenreLoanCounts AS (
    SELECT
        B.genre,
        B.title,
        A.author_name,
        COUNT(L.loan_id) AS loan_count,
        RANK() OVER (PARTITION BY B.genre ORDER BY COUNT(L.loan_id) DESC) AS rank_in_genre
    FROM
        books B
    JOIN
        authors A ON B.author_id = A.author_id
    JOIN
        book_copies BC ON B.book_id = BC.book_id
    LEFT JOIN
        loans L ON BC.copy_id = L.copy_id
    GROUP BY
        B.book_id, B.title, B.genre, A.author_name
)
SELECT
    genre,
    title,
    author_name,
    loan_count,
    rank_in_genre
FROM
    GenreLoanCounts
WHERE
    rank_in_genre <= 3
ORDER BY
    genre ASC, rank_in_genre ASC;

-- Query 8.4: Loan Frequency Comparison
WITH MonthlyLoans AS (
    SELECT
        member_id,
        DATE_FORMAT(loan_date, '%Y-%m') AS year_month,
        COUNT(loan_id) AS loans_this_month
    FROM
        loans
    GROUP BY
        member_id, DATE_FORMAT(loan_date, '%Y-%m')
)
SELECT
    M.first_name,
    M.last_name,
    ML.year_month,
    ML.loans_this_month,
    LAG(ML.loans_this_month, 1, 0) OVER (PARTITION BY ML.member_id ORDER BY ML.year_month) AS loans_last_month,
    ML.loans_this_month - LAG(ML.loans_this_month, 1, 0) OVER (PARTITION BY ML.member_id ORDER BY ML.year_month) AS difference
FROM
    MonthlyLoans ML
JOIN
    members M ON ML.member_id = M.member_id
ORDER BY
    M.last_name, ML.year_month DESC;

-- Query 8.5: Next Event for Each Member
WITH NextEvents AS (
    SELECT
        M.first_name,
        M.last_name,
        E.event_name,
        E.event_date,
        ROW_NUMBER() OVER (PARTITION BY M.member_id ORDER BY E.event_date ASC) AS rn
    FROM
        members M
    JOIN
        event_registrations ER ON M.member_id = ER.member_id
    JOIN
        events E ON ER.event_id = E.event_id
    WHERE
        E.event_date >= CURDATE()
)
SELECT
    first_name,
    last_name,
    event_name AS next_event_name,
    event_date
FROM
    NextEvents
WHERE
    rn = 1
ORDER BY
    event_date ASC;

-- Query 8.6: Moving Average of Loans
WITH DailyLoans AS (
    SELECT
        DATE(loan_date) AS loan_day,
        COUNT(loan_id) AS loans_that_day
    FROM
        loans
    GROUP BY
        loan_day
)
SELECT
    loan_day,
    loans_that_day,
    AVG(loans_that_day) OVER (ORDER BY loan_day ASC ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS seven_day_moving_avg
FROM
    DailyLoans
ORDER BY
    loan_day DESC
LIMIT 30;

-- Query 8.7: Percentile Ranking of Fines
SELECT
    M.first_name,
    M.last_name,
    F.fine_amount,
    ROUND(PERCENT_RANK() OVER (ORDER BY F.fine_amount ASC) * 100, 2) AS percentile_rank_pct
FROM
    fines F
JOIN
    loans L ON F.loan_id = L.loan_id
JOIN
    members M ON L.member_id = M.member_id
WHERE
    F.paid = FALSE
ORDER BY
    percentile_rank_pct DESC;

-- Query 8.8: Gap Analysis - Days Between Loans
SELECT
    M.first_name,
    M.last_name,
    L.loan_date,
    LAG(L.loan_date) OVER (PARTITION BY M.member_id ORDER BY L.loan_date) AS previous_loan_date,
    DATEDIFF(L.loan_date, LAG(L.loan_date) OVER (PARTITION BY M.member_id ORDER BY L.loan_date)) AS days_gap
FROM
    members M
JOIN
    loans L ON M.member_id = L.member_id
ORDER BY
    M.last_name, L.loan_date;