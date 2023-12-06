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
-- turn off email delivery here before running this script set to System email only: 
-- https://oneredwood--qa.sandbox.lightning.force.com/lightning/setup/OrgEmailSettings/home



EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Account'
--EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'PriceBook2','pkchunk'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Opportunity','pkchunk'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'OpportunityPartner'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Contact'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'OpportunityContactRole'

-- Add any other objects as needed
---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Opportunity_Update' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.[Opportunity_Update];

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

--- Create CTE table for contact roles labeled 'Partner' on opportunities
with contact_partners_all as (
select
cr.*
,c.AccountId
,ROW_NUMBER() OVER (PARTITION BY cr.OpportunityId ORDER BY cr.CreatedDate DESC) AS rn
from SourceQA.dbo.OpportunityContactRole cr
left join SourceQA.dbo.Contact c on cr.ContactId = c.Id
where Role like '%Partner%'
),

contact_partners as (
select
OpportunityId
,ContactId
,AccountId
from contact_partners_all where rn = 1
)

-- select * from contact_partners  where OpportunityId = '0063t000015GWuFAAW'

Select 
	O.ID as Id,
	CAST('' as nvarchar(2000)) as Error,
	MAX(O.AccountID) as REF_AccountID,
	MAX(O.PartnerAccountId) as REF_PartnerAccountId,
	MAX(coalesce(OP.AccountToId,cp.AccountId)) as PartnerAccountId,
	MAX(0+OP.IsPrimary) as REF_IsPrimaryPartner,
	CASE WHEN MAX(OP.AccountToId) IS NULL THEN 'Direct' ELSE 'Indirect' END  as Opportunity_Channel__c,
	MAX(coalesce(PartnerCon.Id,cp.ContactId)) as Partner_Contact__c,
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
	LEFT JOIN contact_partners cp on cp.OpportunityId = O.Id

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
-- error sheet: https://docs.google.com/spreadsheets/d/1SK1gMkJIFMnfEYF2GdoG0lxQwEzM4j3ASqcbx-SRDA0/edit#gid=293700337
-------------------^^^^^^^^^^ Link to validation errors ^^^^^^^^^^^^
---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

Select error, * from Opportunity_Update_Result a where error not like '%success%'

Select error, count(*) from Opportunity_Update_Result
group by error

-- https://docs.google.com/spreadsheets/d/1wffRr25qMwfopOwPw4dHHfPOY-8xsXyEJmGrQIUP7lg/edit#gid=1768183546
-- ^^^^^^^^^^^^^ query can be used to check for exceptions. Check SSMS query tab ^^^^^^^^^^^^^^^^