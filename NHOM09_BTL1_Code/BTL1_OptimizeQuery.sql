-- CAU TRUY VAN CHUA TOI UU CUC BO
SELECT DISTINCT C.CustomerID, CustomerName, CustomerType
FROM 
    (SELECT * FROM CN1.EMPLOYEE
    UNION
    SELECT * FROM CN2.EMPLOYEE@DR_DR2_LINK) E,
    (SELECT * FROM CN1.BILL
    UNION
    SELECT * FROM CN2.BILL@DR_DR2_LINK) B,
    (SELECT * FROM CN1.BRANCH
    UNION
    SELECT * FROM CN2.BRANCH@DR_DR2_LINK) BR, 
    (SELECT * FROM CN1.CUSTOMER_STAFF
    UNION
    SELECT * FROM CN2.CUSTOMER_STAFF@DR_DR2_LINK) C
WHERE B.EmployeeID = E.EmployeeID
	AND B.CustomerID = C.CustomerID
	AND BR.BranchID = E.BranchID
	AND Total >= 1000000
	AND BillDate = '05-DEC-21'
	AND BranchName = 'Nguyen Du';

---------------------------------------------------------

-- EPLAIN CAU TRUY VAN CHUA TOI UU CUC BO
EXPLAIN PLAN FOR
SELECT DISTINCT C.CustomerID, CustomerName, CustomerType
FROM 
    (SELECT * FROM CN1.EMPLOYEE
    UNION
    SELECT * FROM CN2.EMPLOYEE@DR_DR2_LINK) E,
    (SELECT * FROM CN1.BILL
    UNION
    SELECT * FROM CN2.BILL@DR_DR2_LINK) B,
    (SELECT * FROM CN1.BRANCH
    UNION
    SELECT * FROM CN2.BRANCH@DR_DR2_LINK) BR, 
    (SELECT * FROM CN1.CUSTOMER_STAFF
    UNION
    SELECT * FROM CN2.CUSTOMER_STAFF@DR_DR2_LINK) C
WHERE B.EmployeeID = E.EmployeeID
	AND B.CustomerID = C.CustomerID
	AND BR.BranchID = E.BranchID
	AND Total >= 1000000
	AND BillDate = '05-DEC-21'
	AND BranchName = 'Nguyen Du';
SELECT * FROM table(dbms_xplan.display );

--------------------------------------------------

-- CAU TRUY VAN RUT GON TOI UU CUC BO
SELECT DISTINCT C.CustomerID, CustomerName, CustomerType
FROM CN2.BILL@DR_DR2_LINK B, CN1.CUSTOMER_STAFF C
WHERE B.CustomerID = C.CustomerID
	AND Total >= 1000000
	AND BillDate = '05-DEC-21';

---------------------------------

-- EXPLAIN CAU TRUY VAN TOI UU CUC BO
EXPLAIN PLAN FOR
SELECT /*+ gather_plan_statistics */  DISTINCT C.CustomerID, CustomerName, CustomerType
FROM CN2.BILL@DR_DR2_LINK B, CN1.CUSTOMER_STAFF C
WHERE B.CustomerID = C.CustomerID
	AND Total >= 1000000
	AND BillDate = '05-DEC-21';
SELECT * FROM table(dbms_xplan.display );