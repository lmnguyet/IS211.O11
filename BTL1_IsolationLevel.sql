
--1. Lost Update
-- CN2
CREATE DATABASE LINK DR2_DR_LINK CONNECT TO DIRECTOR IDENTIFIED BY DR USING 'CN1';

-- Thoi diem: T0
-- CN1
SELECT EmployeeAddress FROM CN1.EMPLOYEE WHERE EmployeeID = 'EMP01'; -- Vinh Phuc
-- CN2
SELECT EmployeeAddress FROM CN1.EMPLOYEE@DR2_DR_LINK WHERE EmployeeID = 'EMP01'; -- Vinh Phuc
-- Thoi diem: T1
-- CN1
UPDATE CN1.EMPLOYEE SET EmployeeAddress = 'TP.HCM' WHERE EmployeeID='EMP01';
-- Thoi diem: T2
-- CN2
UPDATE CN1.EMPLOYEE@DR2_DR_LINK 
SET EmployeeAddress = 'Hai Phong' 
WHERE EmployeeID = 'EMP01';
-- Thoi diem: T3
-- CN1
COMMIT;
-- Thoi diem: T4
-- CN2
COMMIT;
-- Thoi diem: T5
-- CN1
SELECT EmployeeAddress FROM CN1.EMPLOYEE WHERE EmployeeID = 'EMP01'; -- Hai Phong
-- CN2
SELECT EmployeeAddress FROM CN1.EMPLOYEE@DR2_DR_LINK WHERE EmployeeID = 'EMP01'; -- Hai Phong

-- Giai phap
-- CN1, CN2
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- Thoi diem: T1
-- CN1
UPDATE CN1.EMPLOYEE SET EmployeeAddress = 'TP.HCM' WHERE EmployeeID='EMP01';
-- Thoi diem: T2
-- CN2
UPDATE CN1.EMPLOYEE@DR2_DR_LINK SET EmployeeAddress = 'Ha Noi' WHERE EmployeeID = 'EMP01'; -- Error
-- Thoi diem: T3
-- CN1
COMMIT;
SELECT EmployeeAddress FROM CN1.EMPLOYEE WHERE EmployeeID = 'EMP01'; -- TP.HCM

-----------------------------------------------------------------------------------------------

--2. Unrepeatable Read
-- Thoi diem: T0
-- CN1
SELECT EmployeeAddress FROM CN1.EMPLOYEE WHERE EmployeeID = 'EMP01'; -- 012345678
-- Thoi diem: T1
-- CN2
UPDATE CN1.EMPLOYEE@DR2_DR_LINK SET PhoneNumber = '0999999' WHERE EmployeeID = 'EMP01';
-- Thoi diem: T2
-- CN2
COMMIT;
-- Thoi diem: T3
-- CN1
SELECT PhoneNumber FROM CN1.EMPLOYEE WHERE EmployeeID = 'EMP01'; -- 0999999


-- Giai phap
-- CN1, CN2
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- Thoi diem: T0
-- CN1
SELECT EmployeeAddress FROM CN1.EMPLOYEE WHERE EmployeeID = 'EMP01'; -- 0999999
-- Thoi diem: T1
-- CN2
UPDATE CN1.EMPLOYEE@DR2_DR_LINK SET PhoneNumber = '011111' WHERE EmployeeID = 'EMP01';
-- Thoi diem: T2
-- CN2
COMMIT;
-- Thoi diem: T3
-- CN1
SELECT PhoneNumber FROM CN1.EMPLOYEE WHERE EmployeeID = 'EMP01'; -- 0999999

------------------------------------------------------------------------------------

-- 3. Phantom Read
-- Thoi diem: T0
-- CN1
SELECT * FROM CN1.EMPLOYEE WHERE EmployeeID = 'EMP10'; -- 1 row
-- Thoi diem: T1
-- CN2
DELETE FROM CN1.EMPLOYEE@DR2_DR_LINK WHERE EmployeeID='EMP10';
-- Thoi diem: T2
-- CN2
COMMIT;
-- Thoi diem: T3
-- CN1
SELECT * FROM CN1.EMPLOYEE WHERE EmployeeID = 'EMP10'; -- 0 row

-- Giai phap
INSERT INTO CN1.EMPLOYEE VALUES ('EMP10','Luu Tran Anh Khoa',to_date('01/01/2001','dd/mm/yyyy'),'0366866701','Long An','BR01');
COMMIT;
-- CN1, CN2
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- Thoi diem: T0
-- CN1
SELECT * FROM CN1.EMPLOYEE WHERE EmployeeID = 'EMP10'; -- 1 row
-- Thoi diem: T1
-- CN2
DELETE FROM CN1.EMPLOYEE@DR2_DR_LINK WHERE EmployeeID='EMP10';
-- Thoi diem: T2
-- CN2
COMMIT;
-- Thoi diem: T3
-- CN1
SELECT * FROM CN1.EMPLOYEE WHERE EmployeeID = 'EMP10'; -- 1 row

---------------------------------------------------------------------------------

--4. Deadlock (Manager)
-- CN2
CREATE DATABASE LINK MN2_MN_LINK CONNECT TO MANAGER_BR1 IDENTIFIED BY MN USING 'CN1';
-- CN1
SELECT * FROM CN1.ITEMMANAGE_MANAGER; -- IT01, IT02: Duoc phep ban
-- CN1
SELECT * FROM CN1.ITEMMANAGE_MANAGER@MN2_MN_LINK; -- IT01, IT02: Duoc phep ban
-- Thoi diem: T0
-- CN1
UPDATE CN1.ITEMMANAGE_MANAGER SET SaleStatus = 'Khong duoc ban' WHERE ItemID='IT01';
-- Thoi diem: T1
-- CN2
UPDATE CN1.ITEMMANAGE_MANAGER@MN2_MN_LINK SET SaleStatus ='Khong duoc ban' where ItemID='IT02';
-- Thoi diem: T2
-- CN1
UPDATE CN1.ITEMMANAGE_MANAGER SET SaleStatus ='Duoc phep ban' where ItemID='IT02';
-- Thoi diem: T3
-- CN2
UPDATE CN1.ITEMMANAGE_MANAGER@MN2_MN_LINK SET SaleStatus = 'Duoc phep ban' WHERE ItemID='IT01';
-- CN1: ORA-00060: deadlock detected while waiting for resource
-- Thoi diem: T4
-- CN1
COMMIT;
-- Thoi diem: T5
-- CN1
SELECT * FROM CN1.ITEMMANAGE_MANAGER; -- IT01: Khong duoc ban, IT02: Duoc phep ban
-- Thoi diem: T6
-- CN2
COMMIT;
-- Thoi diem: T7
-- CN1
SELECT * FROM CN1.ITEMMANAGE_MANAGER; -- IT01: Duoc phep ban, IT02: Khong duoc ban
-- CN2
SELECT * FROM CN1.ITEMMANAGE_MANAGER@MN2_MN_LINK; -- IT01: Duoc phep ban, IT02: Khong duoc ban
