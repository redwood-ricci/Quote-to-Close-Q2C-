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
--EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'PriceBook2','pkchunk'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Opportunity','pkchunk'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'OpportunityPartner'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Contact'
-- Add any other objects as needed


---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Opportunity_Update' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.[Opportunity_Update]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select 
	O.ID as Id,
	CAST('' as nvarchar(2000)) as Error,
	MAX(O.AccountID) as REF_AccountID,
	MAX(O.PartnerAccountId) as REF_PartnerAccountId,
	MAX(OP.AccountToId) as PartnerAccountId, 
	MAX(0+OP.IsPrimary) as REF_IsPrimaryPartner,
	CASE WHEN MAX(OP.AccountToId) IS NULL THEN 'Direct' ELSE 'Indirect' END  as Opportunity_Channel__c,
	MAX(PartnerCon.Id) as Partner_Contact__c,
	MAX(PartnerCon.Name) as REF_PartnerContactName,
	--PartnerAcc.Name as REF_PartnerAccountName,

-- MIGRATION FIELDS 																						
	MAX(O.ID) + '-NEO' as Opp_Migration_Id__c

 INTO StageQA.dbo.Opportunity_Update

FROM SourceQA.dbo.Opportunity O
	INNER JOIN SourceQA.dbo.Account Acct 
		ON O.AccountID = Acct.ID 
	LEFT JOIN SourceQA.dbo.OpportunityPartner OP
		on OP.OpportunityId = O.Id
		and OP.IsPrimary = 'true'
	LEFT JOIN SourceQA.dbo.Contact PartnerCon
		on PartnerCon.AccountId = OP.AccountToId 
		and PartnerCon.Primary_Contact__c = 'true'

WHERE O.Opportunity_Channel__c is  null
	and O.IsClosed = 'false'
	and O.StageName != 'Closed Lost'
	and O.StageName != 'Closed Won'
	and O.SBQQ__Contracted__c = 'false'

GROUP BY O.Id

ORDER BY MAX(Acct.ID)

---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE StageQA.dbo.[Opportunity_Update]
ADD [Sort] int 
GO
WITH NumberedRows AS (
  SELECT *, ROW_NUMBER() OVER (ORDER BY REF_AccountID) AS OrderRowNumber
  FROM StageQA.dbo.[Opportunity_Update]
)
UPDATE NumberedRows
SET [Sort] = OrderRowNumber;


---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------

-- Double check there are no duplicate rows

select Opp_Migration_id__c, count(*)
from StageQA.dbo.[Opportunity_Update]
group by Opp_Migration_id__c
having count(*) > 1

select * from StageQA.dbo.[Opportunity_Update]



---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE StageQA;
EXEC StageQA.dbo.SF_Tableloader 'UPDATE:Bulkapi,batchsize(1)','SANDBOX_QA','Opportunity_Update'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

Select error, * from Opportunity_Update_Result a where error not like '%success%'