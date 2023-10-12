---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: OpportunityLineItem Load Script	
--- Customer: Redwood
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
USE SourceQA;

EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Product2'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'PriceBook2'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'PriceBookEntry'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Opportunity'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'OpportunityLineItem'


---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'OpportunityLineItem_Update' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.[OpportunityLineItem_Update]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

SELECT
	A.ID as Id,
	CAST('' as nvarchar(2000)) as Error,
	OLI.OpportunityID as REF_OpportunityID


-- MIGRATION FIELDS 																						
	A.ID + '-NEO' as OLI_Migration_id__c

INTO StageQA.[dbo].OpportunityLineItem_Update

FROM SourceQA.[dbo].[OpportunityLineItem] OLI
INNER JOIN SourceQA.[dbo].Opportunity O
	on O.ID = OLI.OpportunityID

INNER JOIN  SourceQA.[dbo].Product2 PROD 
	ON OLI.Product2ID = PROD.ID

INNER JOIN  SourceQA.[dbo].Pricebook2 PB 
	ON OLI.Pricebook2ID = PB.ID

LEFT OUTER JOIN  SourceQA.[dbo].PriceBookEntry PBE 
	ON PROD.ID = PBE.Product2id 
	AND PBE.Pricebook2Id = PB.ID


WHERE --


---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE StageQA.[dbo].[OpportunityLineItem_Update]
ADD [Sort] int 
GO
WITH NumberedRows AS (
  SELECT *, ROW_NUMBER() OVER (ORDER BY REF_OpportunityID) AS OrderRowNumber
  FROM StageQA.dbo.[OpportunityLineItem_Update]
)
UPDATE NumberedRows
SET [Sort] = OrderRowNumber;



---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
select OLI_Migration_id__c, count(*)
from StageQA.dbo.[OpportunityLineItem_Update]
group by OLI_Migration_id__c
having count(*) > 1


---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE StageQA;
EXEC StageQA.dbo.SF_Tableloader 'UPDATE:bulkapi,batchsize(10)','SANDBOX_QA','OpportunityLineItem_Update'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

-- Select error, * from OpportunityLineItem_Update_Result a where error not like '%success%'