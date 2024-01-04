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
USE [Source_Production_SALESFORCE];
-- turn off email delivery here before running this script set to System email only: 
-- https://oneredwood--qa.sandbox.lightning.force.com/lightning/setup/OrgEmailSettings/home



EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'Account','pkchunk'
--EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'SANDBOX_QA', 'PriceBook2','pkchunk'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'Opportunity','pkchunk'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'OpportunityPartner','pkchunk'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'Contact','pkchunk'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'OpportunityContactRole','pkchunk'

-- Add any other objects as needed
---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Opportunity_Update' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.[Opportunity_Update];

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

--- Create CTE table for contact roles labeled 'Partner' on opportunities
with contact_partners_all as (
select
cr.*
,c.AccountId
,ROW_NUMBER() OVER (PARTITION BY cr.OpportunityId ORDER BY cr.CreatedDate DESC) AS rn
from Source_Production_SALESFORCE.dbo.OpportunityContactRole cr
left join Source_Production_SALESFORCE.dbo.Contact c on cr.ContactId = c.Id
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
	CASE WHEN MAX(coalesce(OP.AccountToId,cp.AccountId)) IS NULL THEN 'Direct' ELSE 'Indirect' END  as Opportunity_Channel__c,
	MAX(coalesce(PartnerCon.Id,cp.ContactId)) as Partner_Contact__c,
	MAX(PartnerCon.Name) as REF_PartnerContactName,
	--PartnerAcc.Name as REF_PartnerAccountName,

-- MIGRATION FIELDS 																						
	MAX(O.ID) + '-NEO' as Opp_Migration_Id__c

 INTO Stage_Production_SALESFORCE.dbo.Opportunity_Update

FROM Source_Production_SALESFORCE.dbo.Opportunity O
	INNER JOIN Source_Production_SALESFORCE.dbo.Account Acct 
		ON O.AccountID = Acct.ID 
	LEFT JOIN Source_Production_SALESFORCE.dbo.OpportunityPartner OP
		on OP.OpportunityId = O.Id
		and OP.IsPrimary = 'true'
	LEFT JOIN Source_Production_SALESFORCE.dbo.Contact PartnerCon
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
ALTER TABLE Stage_Production_SALESFORCE.dbo.[Opportunity_Update]
ADD [Sort] int 
GO
WITH NumberedRows AS (
  SELECT *, ROW_NUMBER() OVER (ORDER BY REF_AccountID) AS OrderRowNumber
  FROM Stage_Production_SALESFORCE.dbo.[Opportunity_Update]
)
UPDATE NumberedRows
SET [Sort] = OrderRowNumber;


---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------

-- Double check there are no duplicate rows

select Opp_Migration_id__c, count(*)
from Stage_Production_SALESFORCE.dbo.[Opportunity_Update]
group by Opp_Migration_id__c
having count(*) > 1

select * from Stage_Production_SALESFORCE.dbo.[Opportunity_Update]



---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;
EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'UPDATE:Bulkapi,batchsize(1)','Production_SALESFORCE','Opportunity_Update'
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