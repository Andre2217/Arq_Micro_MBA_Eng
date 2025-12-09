-- CREATE DATABASE source_db;
-- \c source_db;

CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name TEXT,
    email TEXT
);

INSERT INTO customers (name, email) VALUES
('John Doe', 'john@example.com'),
('Maria Silva', 'maria@example.com'),
('Pedro Santos', 'pedro@example.com'),
('Carlos', 'carlos@example.com');
