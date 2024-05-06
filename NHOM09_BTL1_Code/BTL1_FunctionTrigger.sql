
-- FUNCTION: Ham thuc hien tinh doanh thu trung binh tai ca 2 chi nhanh cua cac mon thuoc 01 LOAI mon bat ky
CREATE OR REPLACE FUNCTION calculate_avg_revenue_by_item_type(item_type_input VARCHAR2) 
RETURN NUMBER IS
    avg_revenue_cn1 NUMBER := 0;
    avg_revenue_cn2 NUMBER := 0;
    avg_revenue_combined NUMBER := 0;
    total_items_cn1 NUMBER := 0;
    total_items_cn2 NUMBER := 0;
BEGIN
    -- Calculate CN1's average revenue
    SELECT AVG(SubTotal), COUNT(*) INTO avg_revenue_cn1, total_items_cn1
    FROM CN1.BILLDETAIL BD
    JOIN CN1.ITEM I ON BD.ItemID = I.ItemID
    WHERE I.ItemType = item_type_input;

    -- Calculate CN2's average revenue via DBLink
    SELECT AVG(SubTotal), COUNT(*) INTO avg_revenue_cn2, total_items_cn2
    FROM CN2.BILLDETAIL@DR_DR2_LINK BD
    JOIN CN2.ITEM@DR_DR2_LINK I ON BD.ItemID = I.ItemID
    WHERE I.ItemType = item_type_input;

    -- Caculate average
    IF total_items_cn1 + total_items_cn2 > 0 THEN
        avg_revenue_combined := (avg_revenue_cn1 * total_items_cn1 + avg_revenue_cn2 * total_items_cn2) / (total_items_cn1 + total_items_cn2);
    END IF;

    RETURN avg_revenue_combined;
END;
/
-- Cau truy van kiem thu: Tim doanh thu trung binh cua cac mon thuoc loai 'Sinh To'
SELECT calculate_avg_revenue_by_item_type('Sinh To') FROM dual;

-----------------------------------------------------------------------------------------------------

-- TRIGGER: Rang buoc toan ven tren bang BILL, thuc hien cap nhat loai khach hang ('VIP', 'Member', 'Standard') dua vao so tien tich luy
CONNECT CN1/CN1;

CREATE OR REPLACE TRIGGER Bill_After_Insert_Or_Update
AFTER INSERT OR UPDATE OF Total ON BILL
FOR EACH ROW
DECLARE
    v_cumulative_total NUMBER;
    v_customer_type VARCHAR2(25);
    v_new_discount NUMBER;
BEGIN
    -- Check if customer exists in the CUSTOMER_MANAGER table
    SELECT CumulativeTotal INTO v_cumulative_total
    FROM CUSTOMER_MANAGER
    WHERE CustomerID = :NEW.CustomerID;
  
    IF SQL%NOTFOUND THEN
        -- If not found, insert a new record with the Total from the BILL
        INSERT INTO CUSTOMER_MANAGER (CustomerID, CumulativeTotal)
        VALUES (:NEW.CustomerID, :NEW.Total);
        v_cumulative_total := :NEW.Total;
    ELSE
        -- If found, update the cumulative total
        v_cumulative_total := v_cumulative_total + :NEW.Total - NVL(:OLD.Total, 0);
        UPDATE CUSTOMER_MANAGER
        SET CumulativeTotal = v_cumulative_total
        WHERE CustomerID = :NEW.CustomerID;
    END IF;

    -- Determine customer type based on the updated cumulative total
    IF v_cumulative_total >= 500000 THEN
        v_customer_type := 'VIP';
    ELSIF v_cumulative_total >= 300000 THEN
        v_customer_type := 'Member';
    ELSE
        v_customer_type := 'Standard';
    END IF;

    -- Update the customer type
    UPDATE CUSTOMER_STAFF
    SET CustomerType = v_customer_type
    WHERE CustomerID = :NEW.CustomerID;

END Bill_After_Insert_Or_Update;

-- Cau truy van kiem thu: Them 1 hoa don moi co tong tien lon hon 300.000 cho khach hang 'CU01' 
INSERT INTO BILL (BillID, BillDate, CustomerID, EmployeeID, Total)
VALUES ('12346', SYSDATE, 'CU01', 'EMP01', 1000.00);
COMMIT;