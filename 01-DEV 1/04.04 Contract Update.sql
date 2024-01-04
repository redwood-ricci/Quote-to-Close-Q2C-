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
USE Source_Production_SALESFORCE;

EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','Account','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','PriceBook2','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','RecordType','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','SBQQ__Quote__c','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','Opportunity','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','OpportunityLineItem','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','Contract','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','Order','PKCHUNK'

---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Contract_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.[Contract_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

DECLARE @RedwoodNewDeal2024 VARCHAR(100); -- Declares a string variable with a maximum length of 100 characters.
DECLARE @RedwoodLegacyDeal VARCHAR(100);
DECLARE @TieredPriceBook2023 VARCHAR(100);

SET @RedwoodNewDeal2024 = '01sQn000000NscQIAS';
SET @RedwoodLegacyDeal = '01sQn000000NscPIAS';
SET @TieredPriceBook2023 = '01s3t000004H01QAAS';

-- create a temp table of first orders to join with contracts later
WITH order_rank AS (
  SELECT
    ContractId,
	Id as OrderId,
    ROW_NUMBER() OVER (PARTITION BY ContractId ORDER BY EffectiveDate) AS rn -- choose the first order for each contract
  FROM
    Source_Production_SALESFORCE.dbo.[Order]
	where ContractId is not null),

first_orders as ( -- select the order rank and pull out only one row for each contract with the first order for that contract
	select * from order_rank where rn = 1
)

Select 
	Con.ID as Id
	,CAST('' as nvarchar(2000)) as Error

	,MAX(O.OrderId) as [SBQQ__Order__c] -- update existing Contract to link to first order for contract
	,MAX(Con.SBQQ__RenewalPricebookId__c) as REF_ContractRenewalPricebookId__c
	,case when MAX(Con.SBQQ__RenewalPricebookId__c) = @TieredPriceBook2023 then @RedwoodNewDeal2024 -- replace tiered pricebook with Redwood New Deals 2024 else Redwood Legacy Deals 2024
		else @RedwoodLegacyDeal end as [SBQQ__RenewalPricebookId__c]
	,NULL as [SBQQ__AmendmentOpportunityRecordTypeId__c] -- blank out all ammendment opportunity record type IDs
	,CONCAT_WS('-', con.Id, MAX(O.OrderId)) as [Contract_Migration_Id__c]
	,'true' as [SBQQ__PreserveBundleStructureUponRenewals__c] -- uncheck perserve bundle structure box
	,CASE WHEN MAX(OP.AccountToId) IS NULL THEN 'Direct' ELSE 'Indirect' END  as Opportunity_Channel__c
	,MAX(Coalesce(Qte.SBQQ__PrimaryContact__c, Oppty.Primary_Contact__c)) as Primary_Contact__c
	,MAX(PartnerCon.Id) as Partner_Contact__c
	,MAX(PartnerCon.Name) as REF_PartnerContactName
	,MAX(OP.AccountToId) as Partner_Account__c
	,MAX(0+OP.IsPrimary) as REF_IsPrimaryPartner
	/* ADD IN ANY OTHER UPDATES, IF NEEDED */

	/* REFERENCE FIELDS */

	,MAX(Acct.ID) as REF_AccountId
	,MAX(Oppty.Id) as REF_OpportunityID
	,MAX(Qte.Id) as REF_QuoteID
	,MAX(Con.SBQQ__RenewalOpportunity__c) as REF_SBQQ__RenewalOpportunity__c

	INTO Stage_Production_SALESFORCE.dbo.Contract_Load
	FROM Source_Production_SALESFORCE.dbo.[Contract] Con
	Left join First_Orders O
		on Con.ID = O.ContractId
	LEFT JOIN Source_Production_SALESFORCE.dbo.Account Acct 
		ON Con.AccountID = Acct.ID 
	LEFT JOIN Source_Production_SALESFORCE.dbo.SBQQ__Quote__c Qte 
		ON Con.SBQQ__Quote__c = Qte.ID
	LEFT JOIN Source_Production_SALESFORCE.dbo.Opportunity Oppty 
		ON Con.[SBQQ__Opportunity__c] = Oppty.ID
	LEFT JOIN Source_Production_SALESFORCE.dbo.OpportunityPartner OP
		on OP.OpportunityId = Oppty.Id
		and OP.IsPrimary = 'true'
	LEFT JOIN Source_Production_SALESFORCE.dbo.Contact PartnerCon
		on PartnerCon.AccountId = OP.AccountToId 
		and PartnerCon.Primary_Contact__c = 'true'
	Where O.StageName = 'Closed Won'
	and O.Cohort_Close_Date__c >= '2022-01-01'
	--and Con.[SBQQ__RenewalPricebookId__c] != @RedwoodNewDeal2024 -- should uncomment this
	--and Con.[SBQQ__RenewalPricebookId__c] != @RedwoodLegacyDeal -- should uncomment this

GROUP BY Con.Id
	
ORDER BY MAX(Acct.ID);

---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE Stage_Production_SALESFORCE.dbo.[Contract_Load]
ADD [Sort] int 
GO
WITH NumberedRows AS (
  SELECT *, ROW_NUMBER() OVER (ORDER BY REF_AccountId) AS OrderRowNumber
  FROM Stage_Production_SALESFORCE.dbo.[Contract_Load]
)
UPDATE NumberedRows
SET [Sort] = OrderRowNumber;


---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
select ID, count(Contract_Migration_Id__c) -- Change to migrated ID if added to object
from Stage_Production_SALESFORCE.dbo.[Contract_Load]
group by ID
having count(*) > 1

select * from Stage_Production_SALESFORCE.dbo.[Contract_Load]

/*
select *
 from Stage_Production_SALESFORCE.dbo.[Contract_Load]
where ID = '8003t000008OIF1AAO'
*/

---------------------------------------------------------------------------------
-- Scrub
---------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

USE Stage_Production_SALESFORCE; -- uncheck box
EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'UPDATE:bulkapi,batchsize(10)','Production_SALESFORCE','Contract_Load'
----- ^^^^^^^^^ 1 records are failing with the error below  ^^^^^^^^^ -----
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
USE Stage_Production_SALESFORCE;
if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'OpportunityLineItem_DELETE' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.OpportunityLineItem_DELETE;

DECLARE @RedwoodNewDeal2024 VARCHAR(100);
DECLARE @RedwoodLegacyDeal VARCHAR(100);

SET @RedwoodNewDeal2024 = '01sQn000000NscQIAS';
SET @RedwoodLegacyDeal = '01sQn000000NscPIAS';
SET @TieredPriceBook2023 = '01s3t000004H01QAAS';

select
	OLI.ID as Id,
	CAST('' as nvarchar(255)) as Error -- only need ID and a spot for errors to delete an object
into OpportunityLineItem_DELETE
from Source_Production_SALESFORCE.dbo.OpportunityLineItem OLI
	INNER JOIN Source_Production_SALESFORCE.[dbo].Opportunity O
		on O.ID = OLI.OpportunityID
	LEFT JOIN Source_Production_SALESFORCE.dbo.Contract con
		on con.Id = O.SBQQ__RenewedContract__c
where (
	O.IsClosed = 'false'
	and O.Type in ('New Business','Renewal Business')
	and O.StageName not in ('Closed Won','Closed Lost')
	and O.SBQQ__Contracted__c = 'false'
	and O.Pricebook2Id not in (@RedwoodNewDeal2024, @RedwoodLegacyDeal)
)

ALTER TABLE Stage_Production_SALESFORCE.dbo.OpportunityLineItem_DELETE
ADD [Sort] int IDENTITY (1,1)

---- make a stash of the opportunity line items about to be deleted
-- this can be used to re upload them later
-- EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','OpportunityLineItem','PKCHUNK'

-- DROP TABLE Source_Production_SALESFORCE.dbo.OpportunityLineItemStash;

-- drop table OpportunityLineItemStash
select * 
into OpportunityLineItemStash2
from Source_Production_SALESFORCE.dbo.OpportunityLineItem
where Id in (
	select Id from Stage_Production_SALESFORCE.dbo.OpportunityLineItem_DELETE
)

-- these should match
select count(distinct Id) from OpportunityLineItemStash2
select count(distinct Id) from Stage_Production_SALESFORCE.dbo.OpportunityLineItem_DELETE

-- execute delete
EXEC SF_TableLoader 'Delete','[Production_SALESFORCE]','OpportunityLineItem_DELETE'
-- took a ton of time and failed many records: https://oneredwood--qa.sandbox.lightning.force.com/lightning/setup/AsyncApiJobStatus/page?address=%2F750O9000002VVmM%3FsfdcIFrameOrigin%3Dhttps%253A%252F%252Foneredwood--qa.sandbox.lightning.force.com%26clc%3D1

-- scope errors
select count(*) from Source_Production_SALESFORCE.dbo.OpportunityLineItem
select count(*) from Source_Production_SALESFORCE.dbo.OpportunityLineItem where id in (select id from OpportunityLineItemStash2) -- seems like the delete did not work on about 19k records


select Error, count(*)
--into Stage_Production_SALESFORCE.dbo.Order_DELETE2
from Stage_Production_SALESFORCE.dbo.OpportunityLineItem_DELETE_Result
where error not like '%Success%'
group by error

select *
from Stage_Production_SALESFORCE.dbo.OpportunityLineItem_DELETE_Result
where error not like '%ENTITY_IS_DELETED:entity is deleted:--%'


-----
-- update opportunities with contract renwal pricebook ID
-----
-- this uses the renewal opportunity and pricebook from the contract load then pushes the pricebook to the renewal opp
USE Stage_Production_SALESFORCE;
if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Opportunity_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.Opportunity_Load;

DECLARE @RedwoodNewDeal2024 VARCHAR(100); 
DECLARE @RedwoodLegacyDeal VARCHAR(100);
DECLARE @TieredPriceBook2023 VARCHAR(100);

SET @RedwoodNewDeal2024 = '01sQn000000NscQIAS';
SET @RedwoodLegacyDeal = '01sQn000000NscPIAS';
SET @TieredPriceBook2023 = '01s3t000004H01QAAS';

select 
O.Id as Id,
O.StageName as REF_StageName,
O.Pricebook2Id as REF_Pricebook2Id,
CONCAT_WS('-',o.Migration_Opportunity__c,O.Id) as Migration_Opportunity__c, -- just concat the old migration ID with the new one to mark the change
case when (O.Pricebook2Id = @TieredPriceBook2023) then @RedwoodNewDeal2024 else @RedwoodLegacyDeal end as Pricebook2Id --coalesce

into Opportunity_Load
from Source_Production_SALESFORCE.dbo.Opportunity O
where (
	O.IsClosed = 'false'
	and O.Type in ('New Business','Renewal Business')
	and O.StageName not in ('Closed Won','Closed Lost')
	and O.SBQQ__Contracted__c = 'false'
	and O.Pricebook2Id not in (@RedwoodNewDeal2024, @RedwoodLegacyDeal)
)

----------------Validate------------
select * from Opportunity_Load -- why is this only 16 opportunities?
------------------------------------

USE Stage_Production_SALESFORCE;
EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'UPDATE:bulkapi,batchsize(5)','Production_SALESFORCE','Opportunity_Load'

select Error, count(*)
--into Stage_Production_SALESFORCE.dbo.Order_DELETE2
from Stage_Production_SALESFORCE.dbo.Opportunity_Load_Result
where error not like '%Success%'
group by error

select *
from Stage_Production_SALESFORCE.dbo.Opportunity_Load_Result
where error not like '%Success%'
								
--- check box ---

----------------
if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Contract_Bundle_Check_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.Contract_Bundle_Check_Load;

select 
cl.ID as Id
,CAST('' as nvarchar(2000)) as Error
,'false' as SBQQ__RenewalQuoted__c
into Contract_Bundle_Check_Load
from Contract_Load cl

----------Validation------------
select * from Contract_Bundle_Check_Load
--------------------------------

EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'UPDATE:bulkapi,batchsize(1)','Production_SALESFORCE','Contract_Bundle_Check_Load'
---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

-- Select error, * from Stage_Production_SALESFORCE.dbo.Contract_Load_Result a where error not like '%success%'
Select
error,
count(*)
from Stage_Production_SALESFORCE.dbo.Contract_Bundle_Check_Load_Result a where error not like '%success%'
group by error

Select
*
from Stage_Production_SALESFORCE.dbo.Contract_Bundle_Check_Load_Result a where error not like '%success%'


Select
* from Stage_Production_SALESFORCE.dbo.Contract_Load_Result a where REF_AccountId = '0013t00002Qps2cAAB'

-- NOTE WITH UPDATES, DO NOT USE DBAMP'S DELETE. SAVE THE ORIGINAL VALUE AND JUST SET IT BACK WITH ANOTHER UPDATE