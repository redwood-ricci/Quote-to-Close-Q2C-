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
USE SourceQA

EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Pricebook2','PKCHUNK'


---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Pricebook2_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.[Pricebook2_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

Select
	*,
	CAST('' as nvarchar(2000)) as Error

INTO Stage_Production_SALESFORCE.dbo.Pricebook2_Load

FROM SourceQA.dbo.PriceBook2 PB

WHERE Name LIKE '%Redwood% 2024%'
	
---------------------------------------------------------------------------------
--Drop Id from the Column
--EXEC sp_rename 'Stage_Production_SALESFORCE.dbo.Pricebook2_Load.Id', 'ExternalId';

ALTER TABLE Stage_Production_SALESFORCE.dbo.Pricebook2_Load
DROP COLUMN Id, LastModifiedById, LastModifiedDate, CreatedDate, CreatedById;

ALTER TABLE Stage_Production_SALESFORCE.dbo.Pricebook2_Load
ADD Id nchar(18);


---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------

Select * from Stage_Production_SALESFORCE.dbo.Pricebook2_Load


---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(10)','Production_SALESFORCE','Pricebook2_Load'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------
Select error, count(*) as num from Pricebook2_Load_Result a
where error not like '%success%'
group by error
order by num desc