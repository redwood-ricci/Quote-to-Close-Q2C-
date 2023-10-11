---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: SBQQ__QuoteLine__c UPDATE Script	
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
USE <Source>;			/* INSERT CORRECT NAME HERE */

EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'Product2'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'PriceBook2'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'PriceBookEntry'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'SBQQ__Quote__c'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'SBQQ__QuoteLine__c'

---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE <Staging>;  		/* INSERT CORRECT NAME HERE */

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'SBQQ__QuoteLine__c_Update' AND TABLE_SCHEMA = 'dbo')
DROP TABLE <Staging>.dbo.[SBQQ__QuoteLine__c_Update]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------


SELECT
	A.ID as Id,
	CAST('' as nvarchar(2000)) as Error,


-- MIGRATION FIELDS 																						
	'' as Migration_id__c

	
	
INTO SBQQ__QuoteLine__c_Update
FROM <source>.dbo.SBQQ__QuoteLine__c QL


LEFT OUTER JOIN <source>.dbo.Product2 PROD 
	on PROD.[Name] = MAP.NEW_Product
LEFT OUTER JOIN <source>.dbo.Pricebook2 PB 
	ON PB.[Name] = 'XXXXXXXX'	
																						/* NEED TO UPDATE THE NAME */
LEFT OUTER JOIN <source>.dbo.PriceBookEntry PBE 
	on PROD.ID = PBE.Product2Id 
	and PBE.Pricebook2Id = PB.ID

LEFT OUTER JOIN <source>.dbo.SBQQ__Quote__c QTE 
	on SBQQ__Account__c = a.[Correct SF Account ID] 
	AND QTE.Migration_id__c = Concat(a.[Correct SF Account ID], ':', Convert(varchar(10), a.[End Date], 120) )

WHERE --

---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE <Staging>.dbo.[SBQQ__QuoteLine__c_Update]
ADD [Sort] int IDENTITY (1,1)

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE <Staging>.;
EXEC <Staging>.dbo.SF_Tableloader 'UPDATE: bulkapi, batchsize(1)', 'INSERT_LINKED_SERVER_NAME', 'SBQQ__QuoteLine__c_Update'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

-- USE Insert_Database_Name_Here; Select error, * from SBQQ__QuoteLine__c_Update_Result a where error not like '%success%'



