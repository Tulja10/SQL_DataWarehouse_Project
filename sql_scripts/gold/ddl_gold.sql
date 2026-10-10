-- ===============================================================================
-- DDL Script: Create Gold Views
-- ===============================================================================

--     This script creates views for the Gold layer in the data warehouse. 
--     The Gold layer represents the final dimension and fact tables (Star Schema)

--     Each view performs transformations and combines data from the Silver layer 
--     to produce a clean, enriched, and business-ready dataset.

--     These views can be queried directly for analytics and reporting.

-- creating view for customers (dimension table)

CREATE VIEW gold.dim_customers AS
SELECT ROW_NUMBER() OVER(ORDER BY cc.cst_id) AS customer_key,
	cc.cst_id AS customer_id,
	cc.cst_key AS customer_no,
	cc.cst_firstname  AS first_name,
	cc.cst_lastname AS last_name,
	el.cntry AS country,
	cc.cst_martial_status AS martial_status,
	CASE WHEN cc.cst_gndr != 'Unknown' THEN cc.cst_gndr --crm is the master source
		ELSE COALESCE(ec.gen, 'Unknown') END AS gender,
	ec.bdate AS birthdate,
	cc.cst_create_date AS create_date
FROM silver.crm_cust_info cc
LEFT JOIN silver.erp_cust_az12 ec
ON cc.cst_key = ec.cid
LEFT JOIN silver.erp_loc_a101 el
ON cc.cst_key = el.cid;

SELECT * FROM gold.dim_customers;

-- creating view for products (dimension table)

CREATE VIEW gold.dim_products AS
SELECT ROW_NUMBER() OVER(ORDER BY prd_start_dt, prd_key) AS product_key,
	prd_id AS product_id,
	prd_key AS product_no,
	prd_nm AS product_name,
	cat_id AS category_id,
	cat AS category,
	ep.subcat AS subcategory,
	ep.maintenance AS maintenance,
	prd_cost AS cost,
	prd_line AS product_line,
	prd_start_dt AS start_date
FROM
((SELECT * FROM silver.crm_prd_info  --subquery filtering historical data
WHERE prd_end_dt IS NULL) AS cp
LEFT JOIN silver.erp_px_cat_g1v2 ep
ON cp.cat_id = ep.id);

-- creating view for sales (fact table)

CREATE VIEW gold.fact_sales AS
SELECT 
	cs.sls_ord_num AS order_no,
	dp.product_key,   --foreign keys 
	dc.customer_key,
	cs.sls_order_dt AS order_date,
	cs.sls_ship_dt AS ship_date,
	cs.sls_due_dt AS due_date,
	cs.sls_sales AS sales,
	cs.sls_quantity AS quantity,
	cs.sls_price AS price
FROM silver.crm_sales_details cs
LEFT JOIN gold.dim_customers dc  --joining with gold layer tables 
ON cs.sls_cust_id = dc.customer_id  --  To connect to surrogate keys of dim tables
LEFT JOIN gold.dim_products dp
ON cs.sls_prd_key = dp.product_no;


