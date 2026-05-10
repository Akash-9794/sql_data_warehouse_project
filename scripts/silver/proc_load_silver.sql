/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/



create procedure silver.load_silver as 
begin
     declare @start_time datetime, @end_time datetime ,@start_silver_time datetime,@end_silver_time datetime;
     begin try
        set @start_silver_time = getdate();
        -- ============================================================
        -- Load and transform customer data from Bronze to Silver layer
        -- ============================================================
        print'===========================================================================================================';
        print'Performing Cleasing on  Silver Layer';
        print'===========================================================================================================';

        print'-----------------------------------------------------------------------------------------------------------';
        print' Cleasing  CRM Tables';
        print'-----------------------------------------------------------------------------------------------------------';
        set @start_time = getdate();
        print '>> Truncating table : silver.crm_cust_info'
        truncate table silver.crm_cust_info;
        print '>> inserting table : silver.crm_cust_info'
        insert into silver.crm_cust_info(
             cst_id,
             cst_key,
             cst_firstname,
             cst_lastname,
             cst_marital_status,
             cst_gndr,
             cst_create_date
        )

        select 
   
           -- Customer ID
           cst_id,
           -- Customer business key
           cst_key,
           -- Remove leading/trailing spaces from first name
           trim(cst_firstname) as cst_firstname,
           -- Remove leading/trailing spaces from last name
           trim(cst_lastname) as cst_lastname,
           -- Standardize marital status values
           case 
                when upper(trim(cst_marital_status)) = 'S' then 'Single'
                when upper(trim(cst_marital_status)) = 'M' then 'Married'
                else 'n/a'
           end as cst_marital_status,

           -- Standardize gender values
           case 
                when upper(trim(cst_gndr)) = 'F' then 'Female'
                when upper(trim(cst_gndr)) = 'M' then 'Male'
                else 'n/a'
           end as cst_gndr,
           -- Customer creation date
           cst_create_date

        from (
            -- Deduplicate customer records -- Keep latest record based on create date
            select *,
                   row_number() over(
                       partition by cst_id
                       order by cst_create_date desc
                   ) as flag_last

            from bronze.crm_cust_info

        ) t
        -- Keep only latest customer record -- Remove null customer IDs
        where flag_last = 1 and cst_id is not null;
        set @end_time = getdate();
        print '>> Load and cleansing Duration ' + cast(datediff(second,@start_time,@end_time) as nvarchar) + 'seconds' ;

        -- ============================================================
        -- Load and transform product data from Bronze to Silver layer
        -- ============================================================
        set @start_time = getdate();
        print '>> Truncating table : silver.crm_prd_info'
        truncate table silver.crm_prd_info;
        print '>> Inserting table : silver.crm_prd_info'
        insert into silver.crm_prd_info (
                prd_id,
                cat_id,
                prd_key,
                prd_nm,
                prd_cost,
                prd_line,
                prd_start_dt,
                prd_end_dt
        )

        select 

            -- Product ID
            prd_id,

            -- Extract category ID and standardize format
            replace(substring(prd_key,1,5),'-','_') as cat_id,

            -- Extract actual product key
            substring(prd_key,7,len(prd_key)) as prd_key,

            -- Product name
            prd_nm,

            -- Replace null product cost with 0
            isnull(prd_cost,0) as prd_cost,

            -- Standardize product line descriptions
            case upper(trim(prd_line))

                 when 'M' then 'Mountain'
                 when 'R' then 'Road'
                 when 'S' then 'Others Sales'
                 when 'T' then 'Touring'

                 else 'n/a'

            end as prd_line,

            -- Convert product start date to DATE datatype
            cast(prd_start_dt as date) as prd_start_dt,

            -- Calculate product end date
            -- End date = next product start date minus 1 month

            cast(
                dateadd(
                    month,
                    -1,
                    try_cast(
                        lead(prd_start_dt)
                        over(
                            partition by prd_key
                            order by prd_start_dt
                        )
                    as date)
                )
            as date) as prd_end_dt

        from bronze.crm_prd_info;

        set @end_time = getdate();
        print '>> Load and Cleansing Duration ' + cast(datediff(second,@start_time,@end_time) as nvarchar) + 'seconds' ;

        --========================================================================
        set @start_time = getdate();
        -- silver.sales details
        
        print '>> Truncating table : silver.crm_sales_details'
        truncate table silver.crm_sales_details;
        print '>> Inserting table : silver.crm_sales_details'
        insert into silver.crm_sales_details(
                sls_ord_num,
                sls_prd_key,
                sls_cust_id,
                sls_order_dt,
                sls_ship_dt,
                sls_due_dt,
                sls_sales,
                sls_quantity,
                sls_price
        )
         select 
             sls_ord_num,
             sls_prd_key,
             sls_cust_id,
             case 
                when sls_order_dt = 0 or len(sls_order_dt) != 8 then null
                else try_cast(cast(sls_order_dt as varchar) as date)
             end as sls_order_dt,
             case 
                when sls_ship_dt = 0 or len(sls_ship_dt) != 8 then null
                else try_cast(cast(sls_ship_dt as varchar) as date)
             end as sls_ship_dt,
             case 
               when sls_due_dt = 0 or len(sls_due_dt) != 8 then null
               else try_cast(cast(sls_due_dt as varchar) as date)
             end as sls_due_dt,
             case
                when sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * abs(sls_price)
                then sls_quantity*abs(sls_price)
                else sls_sales
             end as sls_sales,
             sls_quantity,
             case 
                when sls_price is null or sls_price <= 0 then sls_sales / nullif(sls_quantity,0)
                else sls_price
             end as sls_price

         from bronze.crm_sales_details
         set @end_time = getdate();
         print '>> Load and Cleansing Duration ' + cast(datediff(second,@start_time,@end_time) as nvarchar) + 'seconds' ;

         --==============================================================================================
        print'-----------------------------------------------------------------------------------------------------------';
        print' Cleasing  ERP Tables';
        print'-----------------------------------------------------------------------------------------------------------';
        set @start_time = getdate();
        -- silver.erp_cust_az12
         print '>> Truncating table : silver.erp_cust_az12'
         truncate table silver.erp_cust_az12;
         print '>> Inserting table : silver.erp_cust_az12'
         insert into silver.erp_cust_az12(
                cid,
                bdate,
                gen
         )

        select
           -- Remove 'NAS' prefix from customer id
           case 
              when cid like 'NAS%' then SUBSTRING(cid,4,len(cid))
              else cid
           end as cid,
           -- Replace future birthdates with NULL
           case
              when bdate > getdate() then null
              else bdate
           end as bdate,
           -- Standardize gender values
           case
               when upper(trim(gen)) in ('F','FEMALE') then 'Female'
               when upper(trim(gen)) in ('M','MALE') then 'Male'
               else 'n/a'
            end as gen
        from bronze.erp_cust_az12
        
        set @end_time = getdate();
        print '>> Load and Cleansing Duration ' + cast(datediff(second,@start_time,@end_time) as nvarchar) + 'seconds' ;

        --=============================================================================
        set @start_time = getdate();
        -- silver.erp_loc_a101
        print '>> Truncating table : silver.erp_loc_a101'
        truncate table silver.erp_loc_a101;
        print '>> Inserting table : silver.erp_loc_a101'
        insert into silver.erp_loc_a101(
               cid,
               cntry
        )

        select  
             replace(cid,'-','') as cid,
             case 
                when trim(cntry) in ('USA','US','United States') then 'United States'
                when trim(cntry) is null or trim(cntry) = '' then 'n/a'
                when trim(cntry) = 'DE' then 'Germeny'
                else trim(cntry)
             end as cntry -- Normalize and handle missing values or blank country codes
        from bronze.erp_loc_a101

        set @end_time = getdate();
        print '>> Load and Cleansing Duration ' + cast(datediff(second,@start_time,@end_time) as nvarchar) + 'seconds' ;

        --============================================================================
        set @start_time = getdate();
        -- silver.erp_px_cat_g1v2 
        print '>> Truncating table : silver.erp_px_cat_g1v2'
        truncate table silver.erp_px_cat_g1v2;
        print '>> Inserting table : silver.erp_px_cat_g1v2'
        insert into silver.erp_px_cat_g1v2(
               id,
               cat,
               subcat,
               maintenance
        )

        select id,
               cat,
               subcat,
               maintenance
        from bronze.erp_px_cat_g1v2
        
        set @end_time = GETDATE();
        print '>> Load Duration ' + cast(datediff(second,@start_time,@end_time) as nvarchar) + 'seconds' ;

        print'===========================================================================================================';
        print 'Silver layer loading and Cleansing completed';
        print'===========================================================================================================';
        

        set @end_silver_time = GETDATE();
        print '>> Total silver Load Duration ' + cast(datediff(second,@start_silver_time,@end_silver_time) as nvarchar) + 'seconds' ;
   end try

   begin catch
        print'===========================================================================================================';
        print 'ERROR OCCURED DURING LOADING BRONZE LAYER';
        print 'Error Message : ' + error_message();
        print 'Error Number ; ' + cast(error_number() as nvarchar);
        print 'Error state : ' + cast(error_state() as nvarchar) ;
        print 'Error LINE : ' + cast(error_line() as nvarchar) ;
        print 'Error Procedure : ' + isnull(error_procedure(), 'N/A')  ;
        print 'Error Severity : ' + cast(error_severity() as nvarchar) ;
        print 'Error Time : ' + cast(getdate() as nvarchar);

        print'===========================================================================================================';
 
   end catch 
end

--exec silver.load_silver

