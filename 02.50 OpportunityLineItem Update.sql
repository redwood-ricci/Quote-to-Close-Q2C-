---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: OpportunityLineItem Load Script	
--- Customer: XXXXXXX
--- Primary Developer: Jim Ziller
--- Secondary Developers:  
--- Created Date: 9/21/2023
--- Last Updated: 
--- Change Log: 
--- Prerequisites:
--- 1. 
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- Replicate Data
---------------------------------------------------------------------------------
USE <source>;

EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'Product2'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'PriceBook2'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'PriceBookEntry'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'Opportunity'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'OpportunityLineItem'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'SBQQ__QuoteLine__c'

---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE <Staging>;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'OpportunityLineItem_Update' AND TABLE_SCHEMA = 'dbo')
DROP TABLE <Staging>.dbo.[OpportunityLineItem_Update]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

SELECT
	A.ID as Id,
	CAST('' as nvarchar(2000)) as Error,


-- MIGRATION FIELDS 																						
	'' as Migration_id__c

INTO <Staging>.[dbo].OpportunityLineItem_Update

FROM <Source>.[dbo].[OpportunityLineItem] OLI


LEFT OUTER JOIN map_product MAP 
	ON a.Product = MAP.OLD_Product
LEFT OUTER JOIN  <Source>.[dbo].Product2 PROD 
	ON PROD.[Name] = MAP.NEW_Product
LEFT OUTER JOIN  <Source>.[dbo].Pricebook2 PB 
	ON PB.[Name] = ''
LEFT OUTER JOIN  <Source>.[dbo].PriceBookEntry PBE 
	ON PROD.ID = PBE.Product2id 
	AND PBE.Pricebook2Id = PB.ID


WHERE --


---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE <Staging>.[dbo].[OpportunityLineItem_Update]
ADD [Sort] int IDENTITY (1,1)

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE <Staging>;
EXEC <Staging>.dbo.SF_Tableloader 'UPDATE:bulkapi, batchsize(10)', 'INSERT_LINKED_SERVER_NAME', 'OpportunityLineItem_Update'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

-- Select error, * from OpportunityLineItem_Update_Result a where error not like '%success%'