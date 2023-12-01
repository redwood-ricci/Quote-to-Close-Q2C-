---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Contract Load Script	
--- Customer: Redwood
--- Primary Developer: Jim Ziller
--- Secondary Developers:  
--- Created Date: 10/11/2023
--- Last Updated: 
--- Change Log: 
--- Prerequisites:
--- 1. Disable Workflow Rule "Activate Contract After Billing"
--- 2. Disable Workflow Rule "Activated Contract = Renewal Quoted/Forcast"
--- 3. Disable Workflow Rule "Contract - Expired"
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
/*
We have to remove the Opportunity products from contract renewal opportunity (to support Pricebookid update)
Update the renewal Opportunity with new Pricebookids(based on the Contract Renewal Pricebookid)
11:14
Set Opportunity channel, Partner Account & Partner Contact, subscription start and end date on Contract

1. update contract with new pricebook
2. remove products from contract
*/

---------------------------------------------------------------------------------
-- Replicate Data
---------------------------------------------------------------------------------
USE SourceQA;

EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Account','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','PriceBook2','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','RecordType','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','SBQQ__Quote__c','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Opportunity','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Contract','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','OpportunityLineItem','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Order','PKCHUNK'

---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Contract_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.[Contract_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

DECLARE @RedwoodNewDeal2024 VARCHAR(100); -- Declares a string variable with a maximum length of 100 characters.
DECLARE @RedwoodLegacyDeal VARCHAR(100);
DECLARE @TieredPriceBook2023 VARCHAR(100);

SET @RedwoodNewDeal2024 = '01sO90000008D4xIAE';
SET @RedwoodLegacyDeal = '01sO90000008D4yIAE';
SET @TieredPriceBook2023 = '01s3t000004H01QAAS';

-- create a temp table of first orders to join with contracts later
WITH order_rank AS (
  SELECT
    ContractId,
	Id as OrderId,
    ROW_NUMBER() OVER (PARTITION BY ContractId ORDER BY EffectiveDate) AS rn -- choose the first order for each contract
  FROM
    SourceQA.dbo.[Order]
	where ContractId is not null),

first_orders as ( -- select the order rank and pull out only one row for each contract with the first order for that contract
	select * from order_rank where rn = 1
)

Select 
	Con.ID as Id
	,CAST('' as nvarchar(2000)) as Error

	,O.OrderId as [SBQQ__Order__c] -- update existing Contract to link to first order for contract
	,case when Oppty.Pricebook2Id = @TieredPriceBook2023 then @RedwoodNewDeal2024 -- replace tiered pricebook with Redwood New Deals 2024 else Redwood Legacy Deals 2024
	else @TieredPriceBook2023 end as [SBQQ__RenewalPricebookId__c]
	,'' as [SBQQ__AmendmentOpportunityRecordTypeId__c] -- blank out all ammendment opportunity record type IDs
	,CONCAT_WS('-', con.Id, O.OrderId) as [Contract_Migration_Id__c]
	,'false' as [SBQQ__PreserveBundleStructureUponRenewals__c] -- uncheck perserve bundle structure box
	,'false' as SBQQ__RenewalQuoted__c
	/* ADD IN ANY OTHER UPDATES, IF NEEDED */

	/* REFERENCE FIELDS */

	,Acct.ID as REF_AccountId
	,Oppty.Id as REF_OpportunityID
	,Qte.Id as REF_QuoteID
	,Con.SBQQ__RenewalOpportunity__c as REF_SBQQ__RenewalOpportunity__c

	INTO StageQA.dbo.Contract_Load
	FROM SourceQA.dbo.[Contract] Con
	Left join First_Orders O
		on Con.ID = O.ContractId
	
	LEFT JOIN SourceQA.dbo.Account Acct 
		ON Con.AccountID = Acct.ID 
	LEFT JOIN SourceQA.dbo.SBQQ__Quote__c Qte 
		ON Con.SBQQ__Quote__c = Qte.ID
	LEFT JOIN SourceQA.dbo.Opportunity Oppty 
		ON Con.[SBQQ__Opportunity__c] = Oppty.ID
	Where Con.EndDate >= getdate()
	and Con.Status = 'Activated'
	ORDER BY Acct.ID;

---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE StageQA.dbo.[Contract_Load]
ADD [Sort] int 
GO
WITH NumberedRows AS (
  SELECT *, ROW_NUMBER() OVER (ORDER BY REF_AccountId) AS OrderRowNumber
  FROM StageQA.dbo.[Contract_Load]
)
UPDATE NumberedRows
SET [Sort] = OrderRowNumber;


---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
select ID, count(Contract_Migration_Id__c) -- Change to migrated ID if added to object
from StageQA.dbo.[Contract_Load]
group by ID
having count(*) > 1

/*
select *
 from StageQA.dbo.[Contract_Load]
where ID = '8003t000008OIF1AAO'
*/

---------------------------------------------------------------------------------
-- Scrub
---------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

USE StageQA; -- uncheck box
EXEC StageQA.dbo.SF_Tableloader 'UPDATE:bulkapi,batchsize(10)','SANDBOX_QA','Contract_Load'
----- ^^^^^^^^^ 15 records are failing with the error below  ^^^^^^^^^ -----
--- https://docs.google.com/spreadsheets/d/19x56hjw2SrNQlS0aZpXwjUMAs-kq6NcjJ0pUV8K5tEM/edit?usp=sharing
-- 

---------------------
-- inspect contract load errors
---------------------

select error,count(*)
from Contract_Load_Result
where Error not like '%Success%'
group by Error

select *
from Contract_Load_Result
where Error not like '%Success%'

-----
-- Remove all products from contract renewal opportunity
-----

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'OpportunityLineItem_DELETE' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.OpportunityLineItem_DELETE;

select
	OLI.ID as Id,
	CAST('' as nvarchar(255)) as Error -- only need ID and a spot for errors to delete an object
into OpportunityLineItem_DELETE
from SourceQA.dbo.OpportunityLineItem OLI
	INNER JOIN SourceQA.[dbo].Opportunity O
		on O.ID = OLI.OpportunityID
	LEFT JOIN SourceQA.dbo.Contract con
		on con.Id = O.SBQQ__RenewedContract__c
where (
	O.IsClosed = 'false'
	and O.Type in ('New Business','Renewal Business')
	and O.StageName not in ('Closed Won','Closed Lost')
	and O.SBQQ__Contracted__c = 'false'
	and OLI.OpportunityId in ( -- all opportunity line items related to the contract renewals
	select REF_SBQQ__RenewalOpportunity__c from Contract_Load
	where REF_SBQQ__RenewalOpportunity__c is not null )
)

ALTER TABLE StageQA.dbo.OpportunityLineItem_DELETE
ADD [Sort] int IDENTITY (1,1)

---- make a stash of the opportunity line items about to be deleted
-- this can be used to re upload them later
-- EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','OpportunityLineItem','PKCHUNK'

-- DROP TABLE SourceQA.dbo.OpportunityLineItemStash;

-- drop table OpportunityLineItemStash
select * 
into OpportunityLineItemStash
from SourceQA.dbo.OpportunityLineItem
where Id in (
	select Id from StageQA.dbo.OpportunityLineItem_DELETE
)

-- these should match
select count(distinct Id) from OpportunityLineItemStash
select count(distinct Id) from StageQA.dbo.OpportunityLineItem_DELETE

-- execute delete
EXEC SF_TableLoader 'Delete','[SANDBOX_QA]','OpportunityLineItem_DELETE'
-- took a ton of time and failed many records: https://oneredwood--qa.sandbox.lightning.force.com/lightning/setup/AsyncApiJobStatus/page?address=%2F750O9000002VVmM%3FsfdcIFrameOrigin%3Dhttps%253A%252F%252Foneredwood--qa.sandbox.lightning.force.com%26clc%3D1

-- scope errors
select count(*) from SourceQA.dbo.OpportunityLineItem
select count(*) from SourceQA.dbo.OpportunityLineItem where id in (select id from OpportunityLineItemStash) -- seems like the delete did not work on about 19k records


select Error, count(*)
--into StageQA.dbo.Order_DELETE2
from StageQA.dbo.OpportunityLineItem_DELETE_Result
where error not like '%Success%'
group by error

select *
from StageQA.dbo.OpportunityLineItem_DELETE_Result
where error not like '%Success%'


-----
-- update opportunities with contract renwal pricebook ID
-----
-- this uses the renewal opportunity and pricebook from the contract load then pushes the pricebook to the renewal opp

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Opportunity_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.Opportunity_Load;

select 
REF_SBQQ__RenewalOpportunity__c as Id,
CONCAT_WS('-',o.Migration_Opportunity__c,REF_SBQQ__RenewalOpportunity__c) as Migration_Opportunity__c, -- just concat the old migration ID with the new one to mark the change
[SBQQ__RenewalPricebookId__c] as Pricebook2Id
into Opportunity_Load
from Contract_Load cl
left join SourceQA.dbo.Opportunity o on cl.REF_SBQQ__RenewalOpportunity__c = o.Id
where REF_SBQQ__RenewalOpportunity__c is not null

USE StageQA;
EXEC StageQA.dbo.SF_Tableloader 'UPDATE:bulkapi,batchsize(20)','SANDBOX_QA','Opportunity_Load'
								
--- check box ---

----------------
if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Contract_Bundle_Check_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.Contract_Bundle_Check_Load;

select 
cl.ID as Id
,CAST('' as nvarchar(2000)) as Error
,'true' [SBQQ__PreserveBundleStructureUponRenewals__c]
into Contract_Bundle_Check_Load
from Contract_Load cl

EXEC StageQA.dbo.SF_Tableloader 'UPDATE:bulkapi,batchsize(1)','SANDBOX_QA','Contract_Bundle_Check_Load'
---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

-- Select error, * from StageQA.dbo.Contract_Load_Result a where error not like '%success%'
Select
error,
count(*)
from StageQA.dbo.Contract_Load_Result a where error not like '%success%'
group by error

Select
error,

from StageQA.dbo.Contract_Load_Result a where error not like '%success%'
group by error


Select
* from StageQA.dbo.Contract_Load_Result a where REF_AccountId = '0013t00002Qps2cAAB'

-- NOTE WITH UPDATES, DO NOT USE DBAMP'S DELETE. SAVE THE ORIGINAL VALUE AND JUST SET IT BACK WITH ANOTHER UPDATE