-- ===============================================================================
-- Stored Procedure: Load Silver Layer (Bronze -> Silver)
-- ===============================================================================

--     This stored procedure performs the ETL (Extract, Transform, Load) process to 
--     populate the 'silver' schema tables from the 'bronze' schema.
-- 	Actions Performed:
-- 		- Truncates Silver tables.
-- 		- Inserts transformed and cleansed data from Bronze into Silver tables.

-- NOTE: Created table structures of silver schema same as bronze schema tables

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration INTERVAL;
BEGIN
	start_time := clock_timestamp();
    RAISE NOTICE 'Loading Silver layer...................';
    RAISE NOTICE 'Loading CRM data.......................';
    
    RAISE NOTICE 'Truncating table: silver.crm_cust_info';
    TRUNCATE TABLE silver.crm_cust_info;
    RAISE NOTICE 'Inserting data into: silver.crm_cust_info';
	
	--transformation query for crm customer table
    INSERT INTO silver.crm_cust_info (
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_martial_status,
		cst_gndr,
		cst_create_date)
	SELECT cst_id,
		cst_key,
		TRIM(cst_firstname) AS cst_firstname,
		TRIM(cst_lastname) AS cst_lastname,
		CASE WHEN UPPER(TRIM(cst_martial_status))='S' THEN 'Single'
			WHEN UPPER(TRIM(cst_martial_status))='M' THEN 'Married'
			ELSE 'Unknown' END AS cst_martial_status,
		CASE WHEN UPPER(TRIM(cst_gndr))='M' THEN 'Male'
			WHEN UPPER(TRIM(cst_gndr))='F' THEN 'Female'
			ELSE 'Unknown' END AS cst_gndr,
		cst_create_date
	FROM (SELECT *,
	ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS rno
	FROM bronze.crm_cust_info) 
	WHERE rno=1 AND cst_id IS NOT NULL;
    
    RAISE NOTICE '-------------------------------------------------';
    RAISE NOTICE 'Truncating table: silver.crm_prd_info';
    TRUNCATE TABLE silver.crm_prd_info;
    RAISE NOTICE 'Inserting data into: silver.crm_prd_info';
	
    --transformation query for crm products table
	INSERT INTO silver.crm_prd_info(
		prd_id,
		cat_id,
		prd_key,
		prd_nm,
		prd_cost,
		prd_line,
		prd_start_dt,
		prd_end_dt)
	SELECT 
		prd_id,
		REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,  -- Extract category id 
		SUBSTRING(prd_key,7,LENGTH(prd_key)) AS prd_key,  --Extract product key
		prd_nm,
		COALESCE(prd_cost,0) AS prd_cost,  --handling nulls and negatives
		CASE UPPER(TRIM(prd_line))    -- Maps product line codes to descriptive values
			WHEN 'M' THEN 'Mountain'
			WHEN 'T' THEN 'Touring'
			WHEN 'S' THEN 'Other Sales'
			WHEN 'R' THEN 'Road'	
			ELSE 'Unknown' END AS prd_line,
		prd_start_dt,
		LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS prd_end_dt
	FROM bronze.crm_prd_info;    -- making product end date valid by taking one day before of the next start date

    
    RAISE NOTICE '-------------------------------------------------';
    RAISE NOTICE 'Truncating table: silver.crm_sales_details';
    TRUNCATE TABLE silver.crm_sales_details;
    RAISE NOTICE 'Inserting data into: silver.crm_sales_details';
	
    --transformation query for crm sales details table
	INSERT INTO silver.crm_sales_details(
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		sls_order_dt,
		sls_ship_dt,
		sls_due_dt,
		sls_sales,
		sls_quantity,
		sls_price)
	SELECT 
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		CASE WHEN sls_order_dt<=0 OR LENGTH(CAST(sls_order_dt AS VARCHAR))!=8 THEN NULL
			ELSE TO_DATE(CAST(sls_order_dt AS VARCHAR),'YYYYMMDD') END AS sls_order_dt,
		CASE WHEN sls_ship_dt<=0 OR LENGTH(CAST(sls_ship_dt AS VARCHAR))!=8 THEN NULL
			ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) END AS sls_ship_dt,
		CASE WHEN sls_due_dt<=0 OR LENGTH(CAST(sls_due_dt AS VARCHAR))!=8 THEN NULL
			ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) END AS sls_due_dt,
		CASE WHEN sls_sales<=0 OR sls_sales IS NULL OR sls_sales != sls_price*sls_quantity
				THEN  ABS(sls_price) * sls_quantity
			ELSE sls_sales END AS sls_sales,
		sls_quantity,
		CASE WHEN sls_price <=0 OR sls_price IS NULL 
				THEN COALESCE(ABS(sls_sales),0)/sls_quantity
			ELSE sls_price END AS sls_price
	
	FROM bronze.crm_sales_details;
    
    RAISE NOTICE '-------------------------------------------------';
    RAISE NOTICE 'Loading ERP data.......................';
    
    RAISE NOTICE 'Truncating table: silver.erp_cust_az12';
    TRUNCATE TABLE silver.erp_cust_az12;
    RAISE NOTICE 'Inserting data into: silver.erp_cust_az12';
	
    -- transformation query for erp customer info table
	INSERT INTO silver.erp_cust_az12(cid,bdate,gen)
	SELECT 
		REPLACE(cid,'NAS','') AS cid, -- Remove 'NAS' prefix if present
		CASE WHEN  bdate>= NOW() THEN NULL  -- set future bdates to NULL
			ELSE bdate END AS bdate,
		CASE WHEN UPPER(TRIM(gen)) = 'M' THEN 'Male'
			WHEN UPPER(TRIM(gen)) = 'F' THEN 'Female'
			WHEN gen IS NULL OR TRIM(gen)='' THEN 'Unknown'  -- making gender values consistent and handling nulls
		ELSE gen END AS gen
	FROM bronze.erp_cust_az12;
    
    RAISE NOTICE '-------------------------------------------------';
    RAISE NOTICE 'Truncating table: silver.erp_loc_a101';
    TRUNCATE TABLE silver.erp_loc_a101;
    RAISE NOTICE 'Inserting data into: silver.erp_loc_a101';
	
    --transformation query for erp customer location table
	INSERT INTO silver.erp_loc_a101(cid,cntry)
	SELECT 
		REPLACE(cid,'-','') AS cid,  --transforming cid to match with cst_key in crm customer table
		CASE WHEN TRIM(cntry)='DE' THEN 'Germany'
			WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
			WHEN cntry IS NULL OR TRIM(cntry)='' THEN 'Unknown'
		ELSE TRIM(cntry) END AS cntry  --normalize and handle missing and blank spaces 
	FROM bronze.erp_loc_a101;
    
    RAISE NOTICE '-------------------------------------------------';
    RAISE NOTICE 'Truncating table: silver.erp_px_cat_g1v2';
    TRUNCATE TABLE silver.erp_px_cat_g1v2;
    RAISE NOTICE 'Inserting data into: silver.erp_px_cat_g1v2';

	-- transformation query for erp product table
	INSERT INTO silver.erp_px_cat_g1v2(id, cat, subcat, maintenance)
	SELECT id,
		cat,
		subcat,
		maintenance
	FROM bronze.erp_px_cat_g1v2;

	end_time := clock_timestamp();
	duration := end_time - start_time;
	RAISE NOTICE '-------------------------------------------------';
    RAISE NOTICE 'Total execution time: % seconds', EXTRACT(seconds FROM duration);
END;
$$;

--  Use below command to execute the procedure
 CALL silver.load_silver;
	
	