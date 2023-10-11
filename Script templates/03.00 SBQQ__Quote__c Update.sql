---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: SBQQ__Quote__c Update Script	
--- Customer: 
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

EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'Account'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'User'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'RecordType'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'Pricebook2'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'Contact'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'SBQQ__Quote__c'

---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE <Staging>;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'SBQQ__Quote__c_Update' AND TABLE_SCHEMA = 'dbo')
DROP TABLE <Staging>.dbo.[SBQQ__Quote__c_Update]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

SELECT
	A.ID as Id,
	CAST('' as nvarchar(2000)) as Error,


-- MIGRATION FIELDS 																						
	'' as Migration_id__c

INTO  <Staging>.dbo.SBQQ__Quote__c_Update
FROM <Source>.dbo.SBQQ__Quote__c Qte

LEFT OUTER JOIN <Source>.dbo.Account Acct 
	ON Qte.AccountID = Acct.ID 
LEFT OUTER JOIN <Source>.dbo.[User] Usr 
	ON Usr.[Name] = 'XXXXXXXX'																	/* INSERT CORRECT NAME HERE */
LEFT OUTER JOIN <Source>.dbo.[RecordType] RT 
	ON RT.[Name] = 'Approved' 
	AND sobjecttype = 'Sbqq__Quote__c'
LEFT OUTER JOIN <Source>.dbo.Pricebook2 PB 
	ON PB.[Name] = 'XXXXXXXX' 																	/* INSERT CORRECT NAME HERE */
LEFT OUTER JOIN <Source>.dbo.Contact Cont 
	ON a.[Contact ID] = Cont.Id

WHERE 
---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE <Staging>.[SBQQ__Quote__c_Update]
ADD [Sort] int IDENTITY (1,1)

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE Insert_Database_Name_Here;
EXEC <Staging>.dbo.SF_Tableloader 'UPDATE:bulkapi,batchsize(10)','INSERT_LINKED_SERVER_NAME','SBQQ__Quote__c_Update'
---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

-- Select error, * from SBQQ__Quote__c_Update_Result a where error not like '%success%'
