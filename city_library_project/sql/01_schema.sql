
CREATE DATABASE IF NOT EXISTS city_library;
USE city_library;


CREATE TABLE authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    author_name VARCHAR(100) NOT NULL,
    birth_year INT,
    country VARCHAR(50)
);

CREATE TABLE members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    address VARCHAR(200),
    join_date DATE DEFAULT (CURRENT_DATE),
    membership_type ENUM('standard', 'premium', 'student') DEFAULT 'standard',
    status ENUM('active', 'suspended', 'expired') DEFAULT 'active'
);


CREATE TABLE events (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    event_name VARCHAR(100) NOT NULL,
    event_date DATE NOT NULL,
    event_type ENUM('book_club', 'workshop', 'reading_program', 'author_visit') NOT NULL,
    max_attendees INT,
    description TEXT
);

CREATE TABLE audit_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50),
    action ENUM('INSERT', 'UPDATE', 'DELETE'),
    record_id INT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(50) DEFAULT 'SYSTEM',
    description TEXT
);


CREATE TABLE books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    author_id INT NOT NULL,
    isbn VARCHAR(20) NOT NULL UNIQUE,
    publication_year INT,
    genre VARCHAR(50) NOT NULL,
    total_copies INT DEFAULT 1 CHECK (total_copies > 0),
    FOREIGN KEY (author_id) REFERENCES authors(author_id) ON DELETE RESTRICT
);


CREATE TABLE book_copies (
    copy_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    copy_number INT NOT NULL,
    condition ENUM('excellent', 'good', 'fair', 'poor') DEFAULT 'good',
    acquisition_date DATE,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE
);

CREATE TABLE loans (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    copy_id INT NOT NULL,
    loan_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE,
    status ENUM('active', 'returned', 'lost') DEFAULT 'active',
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE RESTRICT,
    FOREIGN KEY (copy_id) REFERENCES book_copies(copy_id) ON DELETE RESTRICT
);


CREATE TABLE fines (
    fine_id INT AUTO_INCREMENT PRIMARY KEY,
    loan_id INT NOT NULL,
    fine_amount DECIMAL(10, 2) NOT NULL CHECK (fine_amount >= 0),
    fine_reason ENUM('overdue', 'damage', 'lost') NOT NULL,
    paid BOOLEAN DEFAULT FALSE,
    payment_date DATE,
    FOREIGN KEY (loan_id) REFERENCES loans(loan_id) ON DELETE CASCADE
);


CREATE TABLE event_registrations (
    registration_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL,
    member_id INT NOT NULL,
    registration_date DATE DEFAULT (CURRENT_DATE),
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE,
    UNIQUE KEY unique_registration (event_id, member_id)
);