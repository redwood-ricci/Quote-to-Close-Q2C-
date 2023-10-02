---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Account UPDATE Script	
--- Customer: Redwood
--- Primary Developer: Jim Ziller
--- Secondary Developers:  Jim Ziller
--- Created Date: 9-18-2023
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
USE <Source>;

EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'Account'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'User'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'RecordType'

---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE <staging>;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Account_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE <staging>.dbo.[Account_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------
USE <staging>;

Select
	A.ID as Id,
	CAST('' as nvarchar(2000)) as Error,


-- MIGRATION FIELDS 																						
	'' as Migration_id__c

INTO <staging>.dbo.Account_Update
FROM <Source>.dbo.Account a


WHERE -- Surgical Filters to make sure each update doesn't go beyond the scope of the update
	
---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE <staging>.dbo.[Account_Load]
ADD [Sort] int IDENTITY (1,1)

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

EXEC <staging>.dbo.SF_Tableloader 'UPDATE: bulkapi, batchsize(10)', 'INSERT_LINKED_SERVER_NAME', 'Account_Load', 'Migration_Id__c'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

-- Select error, * from <staging>.dbo.Account_Load_Result a where error not like '%success%'
