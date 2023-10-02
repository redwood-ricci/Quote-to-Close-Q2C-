---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Opportunity Update Script	
--- Customer: Redwood
--- Primary Developer:  Jim Ziller
--- Secondary Developers: 
--- Created Date: 9/21/2023
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
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'PriceBook2'

EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'sbqq__Quote__c'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'Opportunity'


---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE <Source>;;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Opportunity_Update' AND TABLE_SCHEMA = 'dbo')
DROP TABLE [Opportunity_Update]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------
USE <Source>;


Select 
	A.ID as Id,
	CAST('' as nvarchar(2000)) as Error,


-- MIGRATION FIELDS 																						
	'' as Migration_id__c

INTO <Staging>.dbo.Opportunity_Update

FROM <Source>.dbo.Opportunity O
LEFT OUTER JOIN <Source>.dbo.Account Acct 
	ON a.AccountID = Acct.ID 

LEFT OUTER JOIN <Source>.dbo.Pricebook2 PB 
	ON PB.[Name] = 'XXXXXXXX'																								/* NEED TO UPDATE THE NAME */

	
ORDER BY Acct.ID

---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE [Opportunity_Update]
ADD [Sort] int IDENTITY (1,1)

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE <Staging>;
EXEC <Staging>.dboSF_Tableloader 'UPDATE: Bulkapi, batchsize(10)', '<Source>', 'Opportunity_Update'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

-- Select error, * from Opportunity_Update_Result a where error not like '%success%'