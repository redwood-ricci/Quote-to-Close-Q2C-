---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Attachment Insert Script
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
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Order'
--EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'ContentDocument'

--EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'ContentVersion'

--EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','ContentDocumentLink','PKCHUNK'



---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'ContentDocumentLink_LoadAttachments' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.ContentDocumentLink_LoadAttachments

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select Distinct
	CAST('' as nvarchar(18)) as ID,
	CAST('' as nvarchar(2000)) as error,
	ContentDocumentID as ContentDocumentID,
	O.ID as LinkedEntityID,
	CDL.ShareType as ShareType,
	CDL.Visibility as Visibility, --InternalUsers, AllUsers
	S.Invoice__c as REF_InvoiceID ,-- Same ID as the original LinkedEntityID
	S.SBQQ__Account__c as REF_Account,
	S.SBQQ__Contract__c as REF_Contract
INTO StageQA.dbo.ContentDocumentLink_LoadAttachments
	

  FROM [SourceQA].[dbo].[ContentDocumentLink] CDL
	Inner Join [SourceQA].[dbo].[SBQQ__Subscription__c] S -- Not all subscriptions have an invoice, so using Inner join. Using this to get ContractID, which is what is used to create an order
		on CDL.LinkedEntityId = S.Invoice__c
	left join [SourceQA].[dbo].[Contract] Con
		on S.SBQQ__Contract__c = Con.ID
	left join [SourceQA].[dbo].[Order] O -- Joining back to Order table. Must replicate above for this to work.
		on Con.ID = O.Order_Migration_id__c
	left join SourceQA.dbo.Account Acct
		on Con.AccountId = Acct.ID

	Where con.EndDate >= getdate()
and con.Status = 'Activated'
and Acct.Test_Account__c = 'false'


-- If we need to link to the Order Items and Not Order, then the join can go from the subscription to the OrderItem's Migrated ID field and LinkedEntityID will need updated.

---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE StageQA.dbo.[ContentDocumentLink_LoadAttachments]
ADD [Sort] int 
GO
WITH NumberedRows AS (
  SELECT *, ROW_NUMBER() OVER (ORDER BY LinkedEntityID) AS OrderRowNumber
  FROM StageQA.dbo.[ContentDocumentLink_LoadAttachments]
)
UPDATE NumberedRows
SET [Sort] = OrderRowNumber;


--SELECT *
--FROM INFORMATION_SCHEMA.COLUMNS
--WHERE TABLE_NAME = 'ContentDocumentLink_LoadAttachments';



---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

EXEC StageQA.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(10)','SANDBOX_QA','ContentDocumentLink_LoadAttachments'



---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------


Select error, count(*) as num from ContentDocumentLink_LoadAttachments_Result a
where error not like '%success%'
group by error
order by num desc
