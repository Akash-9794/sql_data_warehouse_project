/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/

create or alter procedure bronze.load_bronze
as
begin
   declare @start_time datetime, @end_time datetime ,@start_bronze_time datetime,@end_bronze_time datetime;

   begin try
        set @start_bronze_time = getdate();
        print'===========================================================================================================';
        print'Loading Bronze Layer';
        print'===========================================================================================================';

        print'-----------------------------------------------------------------------------------------------------------';
        print'Loading CRM Tables';
        print'-----------------------------------------------------------------------------------------------------------';

        set @start_time = getdate();
        print '>> Truncating Table: bronze.crm_cust_info ';
        truncate table bronze.crm_cust_info;
    
        print '>> Inserting Table: bronze.crm_cust_info ';
        bulk insert bronze.crm_cust_info
        from 'C:\Users\akash\OneDrive\Desktop\DATA-Engineer\projects\datawareHouse P1\datasets\source_crm\cust_info.csv'
        with (
            firstrow = 2,
            fieldterminator = ',',
            tablock
        );
        set @end_time = GETDATE();
        print '>> Load Duration ' + cast(datediff(second,@start_time,@end_time) as nvarchar) + 'seconds' ;


        set @start_time = getdate();
        print '>> Truncating Table: bronze.crm_prd_info ';
        truncate table bronze.crm_prd_info;
    
        print '>> Iserting Table: bronze.crm_prd_info ';
        bulk insert bronze.crm_prd_info
        from 'C:\Users\akash\OneDrive\Desktop\DATA-Engineer\projects\datawareHouse P1\datasets\source_crm\prd_info.csv'
        with (
            firstrow = 2,
            fieldterminator = ',',
            tablock
        );

        set @end_time = GETDATE();
        print '>> Load Duration ' + cast(datediff(second,@start_time,@end_time) as nvarchar) + 'seconds' ;


        set @start_time = getdate();
        print '>> Truncating Table: bronze.crm_sales_details ';
        truncate table bronze.crm_sales_details;

        print '>> Inserting Table: bronze.crm_sales_details ';
        bulk insert bronze.crm_sales_details
        from 'C:\Users\akash\OneDrive\Desktop\DATA-Engineer\projects\datawareHouse P1\datasets\source_crm\sales_details.csv'
        with (
            firstrow = 2,
            fieldterminator = ',',
            tablock
        );

        set @end_time = GETDATE();
        print '>> Load Duration ' + cast(datediff(second,@start_time,@end_time) as nvarchar) + 'seconds' ;

        print'-----------------------------------------------------------------------------------------------------------';
        print'Loading ERP Tables';
        print'-----------------------------------------------------------------------------------------------------------';

        set @start_time = getdate();
        print '>> Truncating Table: bronze.erp_CUST_AZ12 ';
        truncate table bronze.erp_CUST_AZ12;
    
        print '>> Inserting Table: bronze.erp_CUST_AZ12 ';
        bulk insert bronze.erp_CUST_AZ12
        from 'C:\Users\akash\OneDrive\Desktop\DATA-Engineer\projects\datawareHouse P1\datasets\source_erp\CUST_AZ12.csv'
        with (
            firstrow = 2,
            fieldterminator = ',',
            tablock
        );
        set @end_time = GETDATE();
        print '>> Load Duration ' + cast(datediff(second,@start_time,@end_time) as nvarchar) + 'seconds' ;


        set @start_time = getdate();
        print '>> Truncating Table: bronze.erp_LOC_A101 ';
        truncate table bronze.erp_LOC_A101;
    
        print '>> Inserting Table: bronze.erp_LOC_A101 ';
        bulk insert bronze.erp_LOC_A101
        from 'C:\Users\akash\OneDrive\Desktop\DATA-Engineer\projects\datawareHouse P1\datasets\source_erp\LOC_A101.csv'
        with (
            firstrow = 2,
            fieldterminator = ',',
            tablock
        );
        set @end_time = GETDATE();
        print '>> Load Duration ' + cast(datediff(second,@start_time,@end_time) as nvarchar) + 'seconds' ;

        
        set @start_time = getdate();
        print '>> Truncating Table: bronze.erp_PX_CAT_G1V2 ';
        truncate table bronze.erp_PX_CAT_G1V2;
    
        print '>> INserting Table: bronze.erp_PX_CAT_G1V2 ';
        bulk insert bronze.erp_PX_CAT_G1V2
        from 'C:\Users\akash\OneDrive\Desktop\DATA-Engineer\projects\datawareHouse P1\datasets\source_erp\PX_CAT_G1V2.csv'
        with (
            firstrow = 2,
            fieldterminator = ',',
            tablock
        );

        set @end_time = GETDATE();
        print '>> Load Duration ' + cast(datediff(second,@start_time,@end_time) as nvarchar) + 'seconds' ;

        print'===========================================================================================================';
        print 'Bronze layer loading completed';
        print'===========================================================================================================';
        
        set @end_bronze_time = GETDATE();
        print '>> Total Bronze Load Duration ' + cast(datediff(second,@start_bronze_time,@end_bronze_time) as nvarchar) + 'seconds' ;
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
end;

--exec bronze.load_bronze

--use datawareHouse

--select table_schema, table_name
--from information_schema.tables

--update bronze.crm_sales_details
--set sls_order_dt = TRY_CAST(sls_order_dt as date),
--    sls_ship_dt = try_cast(sls_ship_dt as date),
--    sls_due_dt = TRY_CAST(sls_due_dt as date )
