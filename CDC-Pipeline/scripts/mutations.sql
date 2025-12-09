-- INSERT
INSERT INTO customers (name, email)
VALUES ('Diana', 'diana@example.com');

-- UPDATE
UPDATE customers
SET email = 'JohnDoe.new@example.com'
WHERE name = 'John Doe';

-- DELETE
DELETE FROM customers
WHERE name = 'Carlos';
