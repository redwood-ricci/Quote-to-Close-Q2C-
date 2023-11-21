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

EXEC SourceNeocol.dbo.SF_Replicate 'SANDBOX_NEOCOL','Pricebook2','PKCHUNK'


---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Pricebook2_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.[Pricebook2_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------
USE StageQA;

Select
	*,
	CAST('' as nvarchar(2000)) as Error
	,PB.Id as External_Id__c


INTO StageQA.dbo.Pricebook2_Load

FROM SourceNeocol.dbo.PriceBook2 PB

WHERE Name LIKE '%Redwood% 2024%'
	
---------------------------------------------------------------------------------
--Drop Id from the Column
--EXEC sp_rename 'StageQA.dbo.Pricebook2_Load.Id', 'ExternalId';

ALTER TABLE StageQA.dbo.Pricebook2_Load
DROP COLUMN Id, LastModifiedById, LastModifiedDate, CreatedDate, CreatedById;

ALTER TABLE StageQA.dbo.Pricebook2_Load
ADD Id nchar(18);


---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------

Select * from StageQA.dbo.Pricebook2_Load


---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

EXEC StageQA.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(10)','SANDBOX_QA','Pricebook2_Load'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------
Select error, count(*) as num from Pricebook2_Load_Result a
where error not like '%success%'
group by error
order by num desc