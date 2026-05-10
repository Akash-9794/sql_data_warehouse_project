/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'silver' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/


-- check for Nulls or Duplicates in primary Key
-- Expectation : No Result


select cst_id , count(*) as cont
from silver.crm_cust_info
group by cst_id 
having count(*) > 1 or cst_id is null

-- check for unwanted Spaces
-- Expectation : No Result
select cst_gndr
from silver.crm_cust_info
where cst_gndr != trim(cst_gndr)

select distinct cst_gndr
from silver.crm_cust_info

select distinct cst_marital_status
from silver.crm_cust_info



----------------------
select * from bronze.crm_prd_info

select prd_id , count(*) as cont
from bronze.crm_prd_info
group by prd_id 
having count(*) > 1 or prd_id is null

-- check unwanted  spaces >> Expected --> no result
select prd_nm
from silver.crm_prd_info
where prd_nm != trim(prd_nm)

select * from silver.crm_prd_info

-- check null
select prd_cost
from silver.crm_prd_info
where prd_cost < 0 or prd_cost is null

select distinct prd_line
from silver.crm_prd_info

select 
   prd_id,
   prd_key,
   prd_nm,
   prd_start_dt,
   prd_end_dt,
   dateadd(month,-1,
       lead(prd_start_dt)
       over(partition by prd_key order by prd_start_dt))
   as prd_end_dt_test
from bronze.crm_prd_info
where prd_key in ('AC-HE-HL-U509-R','AC-HE-HL-U509')

select * 
from silver.crm_prd_info
where prd_end_dt < prd_start_dt

select * from silver.crm_prd_info

 --===================================================
 -- silver.sales details
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
     sls_sales,sls_quantity,
     sls_price
 from bronze.crm_sales_details

 -- check for invaliid dates

 select
  sls_due_dt 
  from bronze.crm_sales_details
  where  sls_due_dt <=  0 or len(sls_due_dt) != 8 


  --32154  5489

  select * 
  from bronze.crm_sales_details
  where sls_order_dt >= sls_ship_dt
        or sls_order_dt >= sls_due_dt 
        or sls_ship_dt >= sls_due_dt
--===============================================
select distinct 
     sls_sales as old_sales,
     sls_quantity ,
     sls_price as old_price,
     case
        when sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * abs(sls_price)
        then sls_quantity*abs(sls_price)
        else sls_sales
     end as sls_sales,
     case 
        when sls_price is null or sls_price <= 0 then sls_sales / nullif(sls_quantity,0)
        else sls_price
     end as sls_price
from bronze.crm_sales_details
where   sls_sales is null or sls_quantity is null or sls_price is null
   or   sls_sales != sls_quantity*sls_price
   or sls_quantity <=0 or sls_price <= 0
order by sls_sales,sls_quantity,sls_price

--last checking after inserted in silver sales details 

select distinct 
     sls_sales ,
     sls_quantity ,
     sls_price
from silver.crm_sales_details
where   sls_sales is null or sls_quantity is null or sls_price is null
   or   sls_sales != sls_quantity*sls_price
   or sls_quantity <=0 or sls_price <= 0
order by sls_sales,sls_quantity,sls_price


select * from silver.crm_sales_details

------------------------------------------------------------------------
select top 10 * from bronze.erp_cust_az12
select top 10 * from silver.crm_cust_info

select 
   case 
      when cid like 'NAS%' then SUBSTRING(cid,4,len(cid))
      else cid
   end as cid,
   case
      when bdate > getdate() then null
      else bdate
   end as bdate,
   case
       when upper(trim(gen)) in ('F','FEMALE') then 'Female'
       when upper(trim(gen)) in ('M','MALE') then 'Male'
       else 'n/a'
    end as gen
from bronze.erp_cust_az12


select * from silver.erp_cust_az12
where  bdate < '1926-01-01' or bdate > getdate()



select 
    cid,
    bdate,
    case
       when gen is null or gen = '' then 'n/a'
       when gen = 'F' then 'Female'
       when gen = 'M' then 'Male'
       else gen
    end as gen

from bronze.erp_cust_az12

select distinct gen
from silver.erp_cust_az12

-- ----------------------------------------------------------------------
-- bronze.erp_loc_a101

select top 20 * from  bronze.erp_loc_a101
select top 20 * from silver.crm_cust_info

select  
     replace(cid,'-','') as cid,
     case 
        when trim(cntry) in ('USA','US','United States') then 'United States'
        when trim(cntry) is null or trim(cntry) = '' then 'n/a'
        when trim(cntry) = 'DE' then 'Germeny'
        else trim(cntry)
     end as cntry
from bronze.erp_loc_a101

use datawareHouse

     select 
     distinct cntry as old_cnrty,
         case 
            when trim(cntry) in ('USA','US','United States') then 'United States'
            when trim(cntry) is null or trim(cntry) = '' then 'n/a'
            when trim(cntry) = 'DE' then 'Germeny'
            else trim(cntry)
         end as cntry
    
        from bronze.erp_loc_a101
        

select distinct cntry
from silver.erp_loc_a101
where cid is null or cid != trim(cid) 

-----------------------------------------------------------------------
-- [bronze].[erp_px_cat_g1v2]

select * from bronze.erp_px_cat_g1v2
select * from silver.crm_prd_info

select distinct id from silver.erp_px_cat_g1v2
where id != trim(id)
-- check unvanted spaces 
select  * from silver.erp_px_cat_g1v2
where cat != trim(cat) or subcat != trim(subcat) or maintenance != trim(maintenance)

-- data standardization 
select distinct maintenance 
from silver.erp_px_cat_g1v2

select * from silver.erp_px_cat_g1v2
