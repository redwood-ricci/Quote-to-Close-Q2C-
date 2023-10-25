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



Select 
	Con.ID as Id,
	CAST('' as nvarchar(2000)) as Error,
	O.ID as [SBQQ__Order__c],


	Acct.ID as REF_AccountId, 
	Oppty.Id as REF_OpportunityID, 
	Qte.Id as REF_QuoteID

	--INTO StageQA.dbo.Contract_Load
	FROM SourceQA.dbo.[Contract] Con
	Inner join SourceQA.dbo.[Order] O
		on Con.ID = O.[Order_Migration_id__c]
	
	LEFT JOIN SourceQA.dbo.Account Acct 
		ON Con.AccountID = Acct.ID 
	LEFT JOIN SourceQA.dbo.SBQQ__Quote__c Qte 
		ON Con.SBQQ__Quote__c = Qte.ID
	LEFT JOIN SourceQA.dbo.Opportunity Oppty 
		ON Con.[SBQQ__Opportunity__c] = Oppty.ID
	--WHERE
	--AND a.AccountID <> 'xxxxxxxxxxxxx'
	ORDER BY Acct.ID

---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE StageQA.dbo.[Contract_Load]
ADD [Sort] int 
GO
WITH NumberedRows AS (
  SELECT *, ROW_NUMBER() OVER (ORDER BY AccountID) AS OrderRowNumber
  FROM StageQA.dbo.[Contract_Load]
)
UPDATE NumberedRows
SET [Sort] = OrderRowNumber;


---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
select ID, count(*) -- Change to migrated ID if added to object
from StageQA.dbo.[Contract_Load]
group by ID
having count(*) > 1

select *
 from StageQA.dbo.[Contract_Load]


---------------------------------------------------------------------------------
-- Scrub
---------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE StageQA;
EXEC SF_Tableloader 'UPDATE:bulkapi,batchsize(10)','SANDBOX_QA','Contract_Load'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

-- Select error, * from Contract_Load_Result a where error not like '%success%'