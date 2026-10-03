
-- DATA QUALITY CHECKS OF BRONZE LAYER TABLES
--NOTE: same data quality checks are used for silver layer tables
----------------------------------------------------
-- checking data quality of CRM customer info table
----------------------------------------------------

SELECT * FROM bronze.crm_cust_info;

--check for nulls and duplicates in PK
SELECT cst_id, COUNT(*) as cnt
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*)>1 OR cst_id IS NULL;

--check for wasted spaces in string values
SELECT cst_firstname
FROM bronze.crm_cust_info 
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_lastname
FROM bronze.crm_cust_info 
WHERE cst_lastname != TRIM(cst_lastname);

SELECT cst_martial_status
FROM bronze.crm_cust_info 
WHERE cst_martial_status != TRIM(cst_martial_status);

SELECT cst_gndr
FROM bronze.crm_cust_info 
WHERE cst_gndr != TRIM(cst_gndr);

--data standardization and consistency check
SELECT  DISTINCT cst_gndr 
FROM bronze.crm_cust_info ;

SELECT  DISTINCT cst_martial_status 
FROM bronze.crm_cust_info ;

----------------------------------------------------
-- checking data quality of CRM products info table
----------------------------------------------------

SELECT * FROM bronze.crm_prd_info;

--check for nulls and duplicates in PK
SELECT prd_id, COUNT(*) as cnt
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*)>1 OR prd_id IS NULL;

--check for wasted spaces in string values
SELECT prd_nm
FROM bronze.crm_prd_info 
WHERE prd_nm!= TRIM(prd_nm);

--check for NULLs and negative numbers
SELECT prd_cost
FROM bronze.crm_prd_info 
WHERE prd_cost IS NULL OR prd_cost<=0;

--data standardization and consistency check
SELECT  DISTINCT prd_line 
FROM bronze.crm_prd_info ;

--check for invalid date orders
SELECT * FROM bronze.crm_prd_info
WHERE prd_start_dt >prd_end_dt;

----------------------------------------------
-- checking data quality of CRM sales table
----------------------------------------------

--checking whether all products and customers mentioned in sales table are also present
--in customer info and product info table
SELECT * FROM bronze.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

SELECT * FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);

--check for nulls and duplicates in PK
--note that order number can be duplicated for same customer buying differnt products.

--check for invalid date orders
SELECT * FROM bronze.crm_sales_details
WHERE sls_order_dt >sls_ship_dt OR sls_order_dt >sls_due_dt;

SELECT sls_order_dt FROM bronze.crm_sales_details
WHERE sls_order_dt<=0 OR LENGTH(sls_order_dt::VARCHAR)<8;

--check for invalid sales, price and quantity
--business rule : sales, price and qty can never be 0, negative or null
--and sales = price * qty.

SELECT  DISTINCT sls_sales,
	sls_quantity,
	sls_price
FROM bronze.crm_sales_details
WHERE sls_sales<=0 OR sls_quantity<=0 OR sls_price<=0
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales != sls_price * sls_quantity;

----------------------------------------------------
-- checking data quality of ERP customer info table
----------------------------------------------------

SELECT * FROM bronze.erp_cust_az12;

--checking duplicates and nulls in PK
SELECT cid, COUNT(*) AS cnt
FROM bronze.erp_cust_az12
GROUP BY cid
HAVING COUNT(*)>1 OR cid IS NULL;

--checks whether all customers present in erp table also present in crm table
SELECT cid FROM bronze.erp_cust_az12
WHERE REPLACE(cid,'NAS','') NOT IN (SELECT cst_key FROM bronze.crm_cust_info);

--check invalid birthdates of customers(we may include dates before business started )
SELECT bdate
FROM bronze.erp_cust_az12
WHERE bdate>= NOW();

-- check unique values in gender column
SELECT DISTINCT gen, LENGTH(gen) AS len
FROM bronze.erp_cust_az12;

--------------------------------------------------------------
-- checking data quality of ERP customer location info table
--------------------------------------------------------------

SELECT * FROM bronze.erp_loc_a101;

-- checks nulls and duplicates in customer id column
SELECT cid, COUNT(*) AS cnt
FROM bronze.erp_loc_a101
GROUP BY cid
HAVING COUNT(*)>1 OR cid IS NULL;

-- check whether all cid present in erp table also exists in crm cust info table
SELECT cid
FROM bronze.erp_loc_a101
WHERE REPLACE(cid,'-','') NOT IN (SELECT cst_key FROM silver.crm_cust_info);

-- checking distinct values of country column
SELECT DISTINCT cntry 
FROM bronze.erp_loc_a101
ORDER BY cntry;
