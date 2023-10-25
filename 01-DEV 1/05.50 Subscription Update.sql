---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Subscription Load Script	
--- Customer: Redwood
--- Primary Developer: Jim Ziller
--- Secondary Developers:  
--- Created Date: 10/11/2023
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

EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'OrderItem','PKCHUNK'

EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Contract','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'SBQQ__Subscription__c','PKCHUNK'

---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'SBQQ__Subscription__c_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.SBQQ__Subscription__c_Load

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------
USE StageQA;

Select
	S.ID as [ID],
	Cast('' as nvarchar(2000)) as Error,

	OI.ID as [SBQQ__OrderProduct__c], -- update existing subscription to link to newly created Order Product

	/* ADD IN ANY OTHER UPDATES, IF NEEDED */


	/* REFERENCE FIELDS */
	S.[SBQQ__Account__c] as REF_AccountID, 
	S.[SBQQ__Contract__c] as REF_ContractID, 
	S.[SBQQ__Product__c] as REF_ProductID, 
	S.[SBQQ__QuoteLine__c] as REF_QuoteLine

	--INTO StageQA.dbo.SBQQ__Subscription__c_Load

	FROM SourceQA.dbo.SBQQ__Subscription__c S
	inner join SourceQA.dbo.OrderItem OI
		on S.ID = OI.OrderProduct_Migration_id__c -- Need to have this field created with unique and external on OrderItem

---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------

ALTER TABLE StageQA.dbo.SBQQ__Subscription__c_Load
ADD [Sort] int 
GO
WITH NumberedRows AS (
  SELECT *, ROW_NUMBER() OVER (ORDER BY REF_ContractID) AS OrderRowNumber
  FROM StageQA.dbo.SBQQ__Subscription__c_Load
)
UPDATE NumberedRows
SET [Sort] = OrderRowNumber;


---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
select OrderProduct_Migration_id__c, count(*) 
from StageQA.dbo.SBQQ__Subscription__c_Load
group by OrderProduct_Migration_id__c
having count(*) > 1

select *
 from StageQA.dbo.SBQQ__Subscription__c_Load


---------------------------------------------------------------------------------
-- Scrub
---------------------------------------------------------------------------------


---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE StageQA;

EXEC StageQA.dbo.SF_Tableloader 'UPDATE:bulkapi,batchsize(10)','SANDBOX_QA','SBQQ__Subscription__c_Load'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

-- USE StageQA; Select error, * from SBQQ__Subscription__c_Load_Result a where error not like '%success%'


-- USE StageQA; EXEC SF_Tableloader 'HardDelete:batchsize(10)', 'SANDBOX_QA', 'SBQQ__QuoteLine__c_Load_Result'

-- USE StageQA; EXEC SF_Tableloader 'Delete:batchsize(10)', 'SANDBOX_QA', 'SBQQ__QuoteLine__c_Load2_Result'


-- NOTE WITH UPDATES, DO NOT USE DBAMP'S DELETE. SAVE THE ORIGINAL VALUE AND JUST SET IT BACK WITH ANOTHER UPDATE