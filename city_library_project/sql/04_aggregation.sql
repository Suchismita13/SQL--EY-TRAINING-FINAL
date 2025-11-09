SELECT
    membership_type,
    COUNT(member_id) AS member_count,
    -- Calculate percentage of total members
    CONCAT(
        ROUND(COUNT(member_id) * 100.0 / (SELECT COUNT(*) FROM members), 0),
        '%'
    ) AS percentage
FROM
    members
GROUP BY
    membership_type
ORDER BY
    member_count DESC;


SELECT
    CASE
        WHEN paid = TRUE THEN 'Collected'
        ELSE 'Outstanding'
    END AS payment_status,
    COUNT(fine_id) AS count_of_fines,
    SUM(fine_amount) AS total_amount
FROM
    fines
GROUP BY
    payment_status
WITH ROLLUP; -- Adds the Overall Total at the end

SELECT
    genre,
    COUNT(DISTINCT book_id) AS number_of_titles,
    SUM(total_copies) AS total_copies
FROM
    books
GROUP BY
    genre
ORDER BY
    total_copies DESC
LIMIT 5;


SELECT
    m.membership_type,
    COUNT(l.loan_id) AS count_of_loans,
    -- Calculate average days a book was held
    ROUND(AVG(DATEDIFF(l.return_date, l.loan_date)), 1) AS average_days_loaned
FROM
    loans l
JOIN
    members m ON l.member_id = m.member_id
WHERE
    l.status = 'returned'
    AND l.return_date IS NOT NULL
GROUP BY
    m.membership_type
ORDER BY
    average_days_loaned DESC;


SELECT
    b.title,
    a.author_name,
    b.genre,
    bc.acquisition_date
FROM
    book_copies bc
JOIN
    books b ON bc.book_id = b.book_id
LEFT JOIN
    authors a ON b.author_id = a.author_id
LEFT JOIN
    loans l ON bc.copy_id = l.copy_id
WHERE
    l.loan_id IS NULL -- Only select copies that have no corresponding loan records
ORDER BY
    bc.acquisition_date ASC;


SELECT
    m.first_name,
    m.last_name,
    COUNT(l.loan_id) AS total_loans,
    SUM(CASE WHEN l.status = 'active' THEN 1 ELSE 0 END) AS active_loans,
    -- Calculate SUM of unpaid fines (using subquery or LEFT JOIN fines)
    COALESCE(SUM(f.fine_amount), 0.00) AS total_unpaid_fines
FROM
    members m
JOIN
    loans l ON m.member_id = l.member_id
LEFT JOIN
    fines f ON l.loan_id = f.loan_id AND f.paid = FALSE
GROUP BY
    m.member_id, m.first_name, m.last_name
HAVING
    COUNT(l.loan_id) >= 1 -- Filter members with at least one loan
ORDER BY
    total_loans DESC
LIMIT 10;


SELECT
    YEAR(loan_date) AS loan_year,
    MONTH(loan_date) AS loan_month,
    COUNT(loan_id) AS total_loans,
    COUNT(DISTINCT member_id) AS unique_borrowers,
    COUNT(DISTINCT bc.book_id) AS unique_books_circulated
FROM
    loans l
JOIN
    book_copies bc ON l.copy_id = bc.copy_id
GROUP BY
    loan_year, loan_month
ORDER BY
    loan_year DESC, loan_month DESC
LIMIT 6;

SELECT
    e.event_name,
    e.event_date,
    e.max_attendees,
    COUNT(er.registration_id) AS registrations,
    -- Calculate capacity percentage
    CONCAT(
        ROUND(COUNT(er.registration_id) * 100.0 / e.max_attendees, 0),
        '%'
    ) AS capacity_percentage
FROM
    events e
LEFT JOIN
    event_registrations er ON e.event_id = er.event_id
WHERE
    e.event_date > CURDATE() -- Filter for future events
GROUP BY
    e.event_id, e.event_name, e.event_date, e.max_attendees
ORDER BY
    COUNT(er.registration_id) DESC, e.event_date ASC;


