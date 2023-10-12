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
USE SourceQA;

EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Account'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'PriceBook2'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Opportunity'
-- Add any other objects as needed


---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE <staging>;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Opportunity_Update' AND TABLE_SCHEMA = 'dbo')
DROP TABLE <Staging>.dbo.[Opportunity_Update]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select 
	A.ID as Id,
	CAST('' as nvarchar(2000)) as Error,
	A.AccountID as REF_AccountID,

-- MIGRATION FIELDS 																						
	A.ID + '-NEO' as Opp_Migration_id__c

INTO <Staging>.dbo.Opportunity_Update

FROM SourceQA.dbo.Opportunity O
LEFT OUTER JOIN SourceQA.dbo.Account Acct 
	ON a.AccountID = Acct.ID 

-- TBD if this join is needed
INNER JOIN SourceQA.dbo.Pricebook2 PB 
	ON O.PricebookID = PB.ID
	
ORDER BY Acct.ID

---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE <staging>.dbo.[Opportunity_Update]
ADD [Sort] int 
GO
WITH NumberedRows AS (
  SELECT *, ROW_NUMBER() OVER (ORDER BY REF_AccountID) AS OrderRowNumber
  FROM <staging>.dbo.[Opportunity_Update]
)
UPDATE NumberedRows
SET [Sort] = OrderRowNumber;


---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------

-- Double check there are no duplicate rows

select Opp_Migration_id__c, count(*)
from <staging>.dbo.[Opportunity_Update]
group by Opp_Migration_id__c
having count(*) > 1



---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE <Staging>;
EXEC <Staging>.dboSF_Tableloader 'UPDATE:Bulkapi,batchsize(10)','SANDBOX_QA','Opportunity_Update'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

-- Select error, * from Opportunity_Update_Result a where error not like '%success%'