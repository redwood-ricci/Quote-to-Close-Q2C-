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
We have to remove the Opportunity products(to support Pricebookid update)
Update the renewal Opportunity with new Pricebookids(based on the Contract Renewal Pricebookid)
11:14
Set Opportunity channel, Partner Account & Partner Contact, subscription start and end date on Contract
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


---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Contract_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.[Contract_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------
USE StageQA;

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
	,case when Oppty.Pricebook2Id = '01s3t000004H01QAAS' then '01sO90000008D4xIAE' -- replace tiered pricebook with Redwood New Deals 2024 else Redwood Legacy Deals 2024
	else '01sO90000008D4yIAE' end as [SBQQ__RenewalPricebookId__c]
	,'' as [SBQQ__AmendmentOpportunityRecordTypeId__c] -- blank out all ammendment opportunity record type IDs
	,CONCAT_WS('-', con.Id, O.OrderId) as [Contract_Migration_Id__c]
	,'false' as [SBQQ__PreserveBundleStructureUponRenewals__c]

	/* ADD IN ANY OTHER UPDATES, IF NEEDED */

	/* REFERENCE FIELDS */

	,Acct.ID as REF_AccountId
	,Oppty.Id as REF_OpportunityID
	,Qte.Id as REF_QuoteID

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
USE StageQA;
EXEC StageQA.dbo.SF_Tableloader 'UPDATE:bulkapi,batchsize(10)','SANDBOX_QA','Contract_Load'

--- check box ---

----------------

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