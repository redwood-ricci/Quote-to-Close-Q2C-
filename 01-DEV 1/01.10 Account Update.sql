---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Account UPDATE Script	
--- Customer: Redwood
--- Primary Developer: Jim Ziller
--- Secondary Developers:  Jim Ziller
--- Created Date: 10/11/2023
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
USE SourceQA;

EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Account'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'User'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'RecordType'

---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Account_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.[Account_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------
USE StageQA;

Select
	A.ID as Id,
	CAST('' as nvarchar(2000)) as Error,


-- MIGRATION FIELDS 																						
	A.ID + '-NEO' as Migration_id__c

INTO StageQA.dbo.Account_Update
FROM SourceQA.dbo.Account a


WHERE -- Surgical Filters to make sure each update doesn't go beyond the scope of the update
	
---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE StageQA.dbo.[Account_Load]
ADD [Sort] int IDENTITY (1,1)


---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------



---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

EXEC StageQA.dbo.SF_Tableloader 'UPDATE:bulkapi,batchsize(10)','SANDBOX_QA','Account_Load'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

-- Select error, * from StageQA.dbo.Account_Load_Result a where error not like '%success%'
