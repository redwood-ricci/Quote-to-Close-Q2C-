---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Contact UPDATE Script	
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
USE <Source>;

EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'Contact'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'User'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'RecordType'

---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE <staging>;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Contact_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE <staging>.dbo.[Contact_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select
	A.ID as Id,
	CAST('' as nvarchar(2000)) as Error,
	A.AccountID as REF_AccountID,


-- MIGRATION FIELDS 																						
	A.ID + '-NEO' as Migration_id__c

INTO <staging>.dbo.Contact_Update
FROM <Source>.dbo.Contact a


WHERE -- Surgical Filters to make sure each update doesn't go beyond the scope of the update
	
---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE <staging>.dbo.[Contact_Load]
ADD [Sort] int 
GO
WITH NumberedRows AS (
  SELECT *, ROW_NUMBER() OVER (ORDER BY REF_AccountID) AS OrderRowNumber
  FROM <staging>.dbo.[Contact_Load]
)
UPDATE NumberedRows
SET [Sort] = OrderRowNumber;


---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------





---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

EXEC <staging>.dbo.SF_Tableloader 'UPDATE:bulkapi,batchsize(10)','INSERT_LINKED_SERVER_NAME','Contact_Load'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

-- Select error, * from <staging>.dbo.Contact_Load_Result a where error not like '%success%'
