
-- CAU TRUY VAN 1: PHEP GIAO
-- Tai CN1, Director tim khach hang VIP da mua hang tai ca 2 chi nhanh
CONNECT DIRECTOR/DR;
CREATE DATABASE LINK DR_DR2_LINK CONNECT TO DIRECTOR_BR2 IDENTIFIED BY DR USING 'CN2';

SELECT DISTINCT CU1.CustomerID, CustomerName, PhoneNumber
FROM CN1.CUSTOMER_STAFF CU1
JOIN CN1.BILL BI1
ON CU1.CustomerID = BI1.CustomerID
WHERE CustomerType = 'VIP'
INTERSECT
SELECT DISTINCT CU2.CustomerID, CustomerName, PhoneNumber
FROM CN2.CUSTOMER_STAFF@DR_DR2_LINK CU2 
JOIN CN2.BILL@DR_DR2_LINK BI2
ON CU2.CustomerID = BI2.CustomerID
WHERE CustomerType = 'VIP';

-- CAU TRUY VAN 2: PHEP HOI
-- Tai CN1, Director thong ke so luong da ban tai tat ca cac chi nhanh cua tung mon
SELECT ItemID, ItemName, COALESCE(SUM(SoLuongDaBan), 0) AS SoLuongDaBan
FROM (
    SELECT IT1.ItemID, ItemName, COALESCE(SUM(Quantity), 0) AS SoLuongDaBan
    FROM CN1.ITEM IT1
    LEFT JOIN CN1.BILLDETAIL BD1
    ON IT1.ItemID = BD1.ItemID
    GROUP BY IT1.ItemID, ItemName
    UNION
    SELECT IT2.ItemID, ItemName, COALESCE(SUM(Quantity), 0) AS SoLuongDaBan
    FROM CN2.ITEM@DR_DR2_LINK IT2
    LEFT JOIN CN2.BILLDETAIL@DR_DR2_LINK BD2
    ON IT2.ItemID = BD2.ItemID
    GROUP BY IT2.ItemID, ItemName
)
GROUP BY ItemID, ItemName
ORDER BY SoLuongDaBan DESC;

-- CAU TRUY VAN 3: PHEP TRU
-- Tai CN1, Director tim nhung mon dang duoc giam gia tai chi nhanh 2 nhung khong duoc giam gia tai chi nhanh 1
SELECT IT2.ItemID, ItemName, ItemType, Discount
FROM CN2.ITEM@DR_DR2_LINK IT2
JOIN CN2.ITEMMANAGE_MANAGER@DR_DR2_LINK IT_MA2
ON IT2.ItemID = IT_MA2.ItemID
WHERE DISCOUNT > 0
MINUS
SELECT IT1.ItemID, ItemName, ItemType, Discount
FROM CN1.ITEM IT1
JOIN CN1.ITEMMANAGE_MANAGER IT_MA1
ON IT1.ItemID = IT_MA1.ItemID
WHERE DISCOUNT > 0;

-- CAU TRUY VAN 4:
-- Tai CN2, Manager tim khach hang da mua hang tai CN2 co so tien tich luy lon nhat
CONNECT MANAGER_BR2/MN;

SELECT CU_ST.CustomerID, CustomerName, PhoneNumber, CustomerType, CumulativeTotal
FROM CN2.CUSTOMER_STAFF CU_ST
JOIN CN2.CUSTOMER_MANAGER CU_MA
ON CU_ST.CustomerID = CU_MA.CustomerID
JOIN CN2.BILL BI
ON CU_MA.CustomerID = BI.CustomerID
ORDER BY CumulativeTotal DESC
FETCH FIRST 1 ROW ONLY;

-- CAU TRUY VAN 5:
-- Tai CN2, Staff thong ke so luong mon an tung loai da ban duoc trong thang 11 tai CN2
CONNECT STAFF_BR2/ST;

SELECT IT.ItemType, SUM(BD.QUANTITY) AS SoLuongDaBan, SUM(BD.SubTotal) AS DoanhThu
FROM CN2.ITEM IT
JOIN CN2.BILLDETAIL BD
ON IT.ItemID = BD.ItemID
JOIN CN2.BILL BI
ON BI.BillID = BD.BillID
WHERE EXTRACT(MONTH FROM BI.BillDate) = 11
GROUP BY IT.ItemType
ORDER BY SoLuongDaBan DESC, DoanhThu DESC;

-- CAU TRUY VAN 6:
-- Tai CN1, Director tim thong tin cac mon da ban hon 50 san pham tai ca 2 chi nhanh
SELECT I.ItemID, I.ItemName,
    (SELECT SUM(BD.Quantity)
    FROM CN1.BILLDETAIL BD
    WHERE BD.ItemID = I.ItemID) AS TotalQuantityCN1,
    (SELECT SUM(BD.Quantity)
    FROM CN2.BILLDETAIL@DR_DR2_LINK BD
    WHERE BD.ItemID = I.ItemID) AS TotalQuantityCN2
FROM CN1.ITEM I
WHERE EXISTS
    (SELECT 1 
    FROM CN2.ITEM@DR_DR2_LINK I2
    WHERE I.ItemID = I2.ItemID)
GROUP BY I.ItemID, I.ItemName
HAVING 
    (SELECT SUM(BD.Quantity)
    FROM CN1.BILLDETAIL BD
    WHERE BD.ItemID = I.ItemID) > 50
    AND 
    (SELECT SUM(BD.Quantity)
    FROM CN2.BILLDETAIL@DR_DR2_LINK BD
    WHERE BD.ItemID = I.ItemID) > 50;

-- CAU TRUY VAN 7:
-- Tai CN1, Director tinh tong doanh thu cua moi chi nhanh
SELECT BranchID, TotalRevenue FROM(
    SELECT BranchID, SUM(Total) AS TotalRevenue
    FROM CN1.BILL, CN1.BRANCH
    GROUP BY BranchID
    UNION ALL
    SELECT BranchID, SUM(Total) AS TotalRevenue
    FROM CN2.BILL@DR_DR2_LINK, CN2.BRANCH@DR_DR2_LINK
    GROUP BY BranchID
);

-- CAU TRUY VAN 8:
-- Tai chi nhanh 2, Manager tim nhan vien co doanh so ban hang cao nhat tai chi nhanh 2
SELECT EmployeeID, SUM(Total) AS TotalSales
FROM CN2.BILL B
GROUP BY EmployeeID
ORDER BY TotalSales DESC
FETCH FIRST 1 ROW ONLY;

-- CAU TRUY VAN 9:
-- Tai CN2, Staff tim mon khong co san de ban
SELECT I.ItemID, I.ItemName
FROM CN2.ITEM I
WHERE NOT EXISTS (
    SELECT 1
    FROM CN2.ITEMMANAGE_STAFF IMS 
    WHERE I.ItemID = IMS.ItemID AND IMS.Availability > 0);

-- CAU TRUY VAN 10
-- Tai CN1, Director xac dinh so luong mon ma moi nhan vien tai ca 2 chi nhanh da lap hoa don
SELECT
    BR.BranchId,
    E.EmployeeID,
    E.EmployeeName,
    COUNT(BD.ItemID) AS TotalItemsSold
FROM
    CN1.BILL B
    JOIN CN1.BILLDETAIL BD ON B.BillID = BD.BillID
    JOIN CN1.EMPLOYEE E ON B.EmployeeID = E.EmployeeID,
    CN1.BRANCH BR
GROUP BY
    E.EmployeeID,
    E.EmployeeName,
    BR.BranchId
UNION ALL
SELECT
    BR.BranchId,
    E.EmployeeID,
    E.EmployeeName,
    COUNT(BD.ItemID) AS TotalItemsSold
FROM
    CN2.BILL@DR_DR2_LINK B
    JOIN CN2.BILLDETAIL@DR_DR2_LINK BD ON B.BillID = BD.BillID
    JOIN CN2.EMPLOYEE@DR_DR2_LINK E ON B.EmployeeID = E.EmployeeID,
    CN2.BRANCH@DR_DR2_LINK BR
GROUP BY
    E.EmployeeID,
    E.EmployeeName,
    BR.BranchId;

