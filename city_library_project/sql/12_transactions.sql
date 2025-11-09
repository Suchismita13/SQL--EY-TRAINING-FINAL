START TRANSACTION;
SELECT copy_id INTO @available_copy
FROM book_copies bc
WHERE book_id = 1
  AND copy_id NOT IN (
    SELECT copy_id FROM loans WHERE status = 'active'
  )
LIMIT 1;
INSERT INTO loans (member_id, copy_id, loan_date, due_date, status)
VALUES (1, @available_copy, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 DAY), 'active');
INSERT INTO audit_log (table_name, action, record_id, description)
VALUES ('loans', 'INSERT', LAST_INSERT_ID(), 'Book checked out');
COMMIT;

START TRANSACTION;
UPDATE fines
SET paid = TRUE, payment_date = CURDATE()
WHERE fine_id = 1;
INSERT INTO audit_log (table_name, action, record_id, description)
VALUES ('fines', 'UPDATE', 1, CONCAT('Fine paid: $', (SELECT fine_amount FROM fines WHERE fine_id = 1)));
UPDATE members
SET status = 'active'
WHERE member_id = (
  SELECT l.member_id FROM fines f
  JOIN loans l ON f.loan_id = l.loan_id
  WHERE f.fine_id = 1
)
AND status = 'suspended'
AND NOT EXISTS (
  SELECT 1 FROM fines f2
  JOIN loans l2 ON f2.loan_id = l2.loan_id
  WHERE l2.member_id = members.member_id
    AND f2.paid = FALSE
    AND f2.fine_id != 1
);
COMMIT;

START TRANSACTION;
INSERT INTO loans (member_id, copy_id, loan_date, due_date, status)
VALUES (1, 5, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 DAY), 'active');
SET @active_count = (
  SELECT COUNT(*) FROM loans
  WHERE member_id = 1 AND status = 'active'
);
IF @active_count > 5 THEN
  ROLLBACK;
  SELECT 'Transaction rolled back: Member has too many active loans' as message;
ELSE
  COMMIT;
  SELECT 'Transaction committed successfully' as message;
END IF;

START TRANSACTION;
UPDATE loans
SET status = 'returned', return_date = CURDATE()
WHERE member_id = 1 AND status = 'active';
INSERT INTO fines (loan_id, fine_amount, fine_reason, paid)
SELECT 
  loan_id,
  GREATEST(0, DATEDIFF(CURDATE(), due_date)) * 0.25 as fine_amount,
  'overdue',
  FALSE
FROM loans
WHERE member_id = 1 
  AND status = 'returned'
  AND return_date > due_date
  AND loan_id NOT IN (SELECT loan_id FROM fines);
INSERT INTO audit_log (table_name, action, record_id, description)
VALUES ('loans', 'UPDATE', 1, CONCAT('Batch return for member 1: ', ROW_COUNT(), ' books'));
COMMIT;

START TRANSACTION;
INSERT INTO members (first_name, last_name, email, membership_type)
VALUES ('Test', 'User', 'test@example.com', 'standard');
SELECT * FROM members WHERE email = 'test@example.com';
COMMIT;
SELECT * FROM members WHERE email = 'test@example.com';

START TRANSACTION;
INSERT INTO members (first_name, last_name, email, membership_type)
VALUES ('Rollback', 'Test', 'rollback@example.com', 'standard');
SELECT * FROM members WHERE email = 'rollback@example.com';
ROLLBACK;
SELECT * FROM members WHERE email = 'rollback@example.com';
