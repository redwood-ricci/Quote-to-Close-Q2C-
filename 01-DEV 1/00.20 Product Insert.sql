---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Product Insert
--- Customer: Redwood
--- Primary Developer: Ajay Santhosh
--- Secondary Developers:  
--- Created Date: 17/11/2023
--- Last Updated: 
--- Change Log: 
--- 	
--- Prerequisites:
--- 1. 
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- Replicate Data
---------------------------------------------------------------------------------
USE SourceNeocol

EXEC SourceNeocol.dbo.SF_Replicate 'SANDBOX_NEOCOL','Product2','PKCHUNK'

---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Product2_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.[Product2_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select
	*
	,CAST('' as nvarchar(2000)) as Error

INTO StageQA.dbo.Product2_Load

FROM SourceNeocol.dbo.Product2 Prod

WHERE Prod.CreatedDate >= DATEADD(day,-90, GETDATE())
	and Prod.IsActive = 'true'
	and Prod.Name not in ('Test Bundle', 'Test Product')
	
---------------------------------------------------------------------------------
--Drop Id from the Column
ALTER TABLE StageQA.dbo.Product2_Load
DROP COLUMN ExternalId, LastModifiedById, LastModifiedDate, CreatedDate, CreatedById;

EXEC sp_rename 'StageQA.dbo.Product2_Load.Id', 'ExternalId';


ALTER TABLE StageQA.dbo.Product2_Load
ADD Id nchar(18);
---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
Select * from StageQA.dbo.Product2_Load


---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE StageQA;

EXEC StageQA.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(100)','SANDBOX_QA','Product2_Load'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------
Select error, count(*) as num from Product2_Load_Result a
where error not like '%success%'
group by error
order by num desc
