-- 1. Query untuk menampilkan customerNumber siapa saja yang memesan productLine Classic Cars dimana total hitung atau COUNT productLine tersebut lebih besar dari 23 :
SELECT c.customerNumber, COUNT(*) AS total_orders
FROM customers c
JOIN orders o ON c.customerNumber = o.customerNumber
JOIN orderdetails od ON o.orderNumber = od.orderNumber
JOIN products p ON od.productCode = p.productCode
JOIN productlines pl ON p.productLine = pl.productLine
WHERE pl.productLine = 'Classic Cars'
GROUP BY c.customerNumber
HAVING total_orders > 23;
-- 

-- 2. Stored procedure pada mysql untuk mengekstrak isi dari ksm_kurs_pajak menjadi 1 table kurs pajak

DELIMITER //

CREATE PROCEDURE extract_kurs_pajak()
BEGIN
    -- Buat tabel baru untuk menyimpan hasil ekstraksi
    CREATE TABLE IF NOT EXISTS kurs_pajak (
        id_ksm_kurs_pajak INT AUTO_INCREMENT PRIMARY KEY,
        kurs_rate DECIMAL(10, 2),
        tgl DATE,
        curr_id INT
    );

    -- Variabel untuk menyimpan tanggal
    DECLARE current_date DATE;
    
    -- Cursor untuk mengambil data dari ksm_kurs_pajak
    DECLARE done INT DEFAULT FALSE;
    DECLARE cur CURSOR FOR 
        SELECT start_date, end_date, kurs_rate, curr_id FROM ksm_kurs_pajak;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Buka cursor
    OPEN cur;

    -- Loop untuk memproses setiap baris dari ksm_kurs_pajak
    kurs_loop: LOOP
        FETCH cur INTO start_date, end_date, kurs_rate, curr_id;
        IF done THEN
            LEAVE kurs_loop;
        END IF;
        
        -- Masukkan semua tanggal dari start_date hingga end_date
        SET current_date = start_date;
        WHILE current_date <= end_date DO
            INSERT INTO kurs_pajak (kurs_rate, tgl, curr_id) VALUES (kurs_rate, current_date, curr_id);
            SET current_date = DATE_ADD(current_date, INTERVAL 1 DAY);
        END WHILE;
    END LOOP;

    -- Tutup cursor
    CLOSE cur;

    -- Menampilkan pesan jika ekstraksi berhasil
    SELECT 'Data kurs pajak berhasil diekstrak.';
END //

DELIMITER ;


-- 

-- 3. Function pada mysql untuk mencari tanggal terkecil dari string yang ter-concatenated

DELIMITER //

CREATE FUNCTION find_min_date(concatenated_dates VARCHAR(255))
RETURNS DATE
BEGIN
    DECLARE min_date DATE;

    -- Temporary table to hold individual dates
    CREATE TEMPORARY TABLE temp_dates (
        temp_date DATE
    );

    -- Loop to insert individual dates into temp table
    WHILE LENGTH(concatenated_dates) > 0 DO
        INSERT INTO temp_dates (temp_date) VALUES (STR_TO_DATE(SUBSTRING_INDEX(concatenated_dates, ', ', 1), '%Y-%m-%d'));
        SET concatenated_dates = SUBSTRING(concatenated_dates, LENGTH(SUBSTRING_INDEX(concatenated_dates, ', ', 1)) + 3);
    END WHILE;

    -- Find minimum date
    SELECT MIN(temp_date) INTO min_date FROM temp_dates;

    -- Drop temporary table
    DROP TEMPORARY TABLE IF EXISTS temp_dates;

    RETURN min_date;
END //

DELIMITER ;

-- 
