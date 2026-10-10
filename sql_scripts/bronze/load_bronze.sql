-- ===============================================================================
-- Stored Procedure: Load Bronze Layer (Source -> Bronze)
-- ===============================================================================

--     This stored procedure loads data into the 'bronze' schema from external CSV files. 
--   Actions Performed:
--     - Truncates the bronze tables before loading data.
--     - Uses the `COPY` command to load data from csv Files to bronze tables.

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration INTERVAL;
BEGIN
	
	start_time := clock_timestamp();
    RAISE NOTICE 'Loading Bronze layer...................';
    RAISE NOTICE 'Loading CRM data.......................';
    
    RAISE NOTICE 'Truncating table: bronze.crm_cust_info';
    TRUNCATE TABLE bronze.crm_cust_info;
    RAISE NOTICE 'Inserting data into: bronze.crm_cust_info';
    COPY bronze.crm_cust_info
    FROM 'E:\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ',');
    
    RAISE NOTICE '-------------------------------------------------';
    RAISE NOTICE 'Truncating table: bronze.crm_prd_info';
    TRUNCATE TABLE bronze.crm_prd_info;
    RAISE NOTICE 'Inserting data into: bronze.crm_prd_info';
    COPY bronze.crm_prd_info
    FROM 'E:\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ',');
    
    RAISE NOTICE '-------------------------------------------------';
    RAISE NOTICE 'Truncating table: bronze.crm_sales_details';
    TRUNCATE TABLE bronze.crm_sales_details;
    RAISE NOTICE 'Inserting data into: bronze.crm_sales_details';
    COPY bronze.crm_sales_details
    FROM 'E:\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ',');
    
    RAISE NOTICE '-------------------------------------------------';
    RAISE NOTICE 'Loading ERP data.......................';
    
    RAISE NOTICE 'Truncating table: bronze.erp_cust_az12';
    TRUNCATE TABLE bronze.erp_cust_az12;
    RAISE NOTICE 'Inserting data into: bronze.erp_cust_az12';
    COPY bronze.erp_cust_az12
    FROM 'E:\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ',');
    
    RAISE NOTICE '-------------------------------------------------';
    RAISE NOTICE 'Truncating table: bronze.erp_loc_a101';
    TRUNCATE TABLE bronze.erp_loc_a101;
    RAISE NOTICE 'Inserting data into: bronze.erp_loc_a101';
    COPY bronze.erp_loc_a101
    FROM 'E:\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ',');
    
    RAISE NOTICE '-------------------------------------------------';
    RAISE NOTICE 'Truncating table: bronze.erp_px_cat_g1v2';
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;
    RAISE NOTICE 'Inserting data into: bronze.erp_px_cat_g1v2';
    COPY bronze.erp_px_cat_g1v2
    FROM 'E:\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ',');
	end_time := clock_timestamp();
	duration := end_time - start_time;
	RAISE NOTICE '-------------------------------------------------';
    RAISE NOTICE 'Total execution time: % seconds', EXTRACT(seconds FROM duration);
END;
$$;

-- Use the below command to execute the procedure 
CALL bronze.load_bronze;



