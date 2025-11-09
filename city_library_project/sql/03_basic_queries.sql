-- Query 3.1: List All Active Members

SELECT
    first_name,
    last_name,
    email,
    membership_type
FROM
    members
WHERE
    status = 'active'
ORDER BY
    last_name ASC,
    first_name ASC;

-- Query 3.2: Find Books Published After 2000


SELECT
    b.title,
    a.author_name,
    b.publication_year AS pub_year,
    b.genre
FROM
    books b
LEFT JOIN
    authors a ON b.author_id = a.author_id
WHERE
    b.publication_year >= 2001
ORDER BY
    b.publication_year DESC;


-- Query 3.3: Search Books by Genre

SELECT
    b.title,
    a.author_name,
    b.genre,
    b.total_copies
FROM
    books b
INNER JOIN
    authors a ON b.author_id = a.author_id
WHERE
    b.genre = 'Fiction'
ORDER BY
    b.title ASC;


-- Query 3.4: Find Overdue Loans
SELECT
    m.first_name,
    m.last_name,
    b.title AS book_title,
    l.loan_date,
    l.due_date,
    DATEDIFF(CURDATE(), l.due_date) AS days_overdue -- Calculates days overdue
FROM
    loans l
JOIN
    members m ON l.member_id = m.member_id
JOIN
    book_copies bc ON l.copy_id = bc.copy_id
JOIN
    books b ON bc.book_id = b.book_id
WHERE
    l.status = 'active'
    AND l.due_date < CURDATE() -- Due date has passed
ORDER BY
    days_overdue DESC;

-- Query 3.5: Members Who Joined in the Last 6 Months

SELECT
    first_name,
    last_name,
    join_date,
    membership_type
FROM
    members
WHERE
    join_date >= DATE_SUB(CURDATE(), INTERVAL 180 DAY)
ORDER BY
    join_date DESC;

-- Query 3.6: Books in Poor Condition

SELECT
    b.title AS book_title,
    bc.copy_number,
    bc.copy_condition, -- Using the corrected column name
    bc.acquisition_date
FROM
    book_copies bc
JOIN
    books b ON bc.book_id = b.book_id
WHERE
    bc.copy_condition IN ('poor', 'fair')
ORDER BY
    FIELD(bc.copy_condition, 'poor', 'fair'), -- Sorts 'poor' before 'fair'
    bc.acquisition_date ASC;


-- Query 3.7: Top 10 Most Expensive Unpaid Fines

SELECT
    m.first_name,
    m.last_name,
    f.fine_amount,
    f.fine_reason,
    l.loan_date
FROM
    fines f
JOIN
    loans l ON f.loan_id = l.loan_id
JOIN
    members m ON l.member_id = m.member_id
WHERE
    f.paid = FALSE
ORDER BY
    f.fine_amount DESC
LIMIT 10;

-- Query 3.8: Upcoming Events This Month

SELECT
    event_name,
    event_date,
    event_type,
    max_attendees
FROM
    events
WHERE
    event_date > CURDATE() -- Event must be in the future
    AND event_date <= DATE_ADD(CURDATE(), INTERVAL 30 DAY) -- Event must be within 30 days
ORDER BY
    event_date ASC;