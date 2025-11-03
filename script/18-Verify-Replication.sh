#!/bin/bash

mysql -u root <<'SQL'
CREATE DATABASE IF NOT EXISTS test_replikasi;
USE test_replikasi;
CREATE TABLE IF NOT EXISTS bukti (id INT, nama VARCHAR(20));
INSERT INTO bukti VALUES (1, 'ReplikasiBerhasil');
SELECT * FROM bukti;
SQL
echo "Data dibuat di Master (Palantir)."