---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Subscription Load Script	
--- Customer: Redwood
--- Primary Developer: Michael 
--- Secondary Developers:  Ajay
--- Created Date: 10/15/2023
--- Last Updated: 
--- Change Log: 
--- Prerequisites:
--- 
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- Replicate Data
---------------------------------------------------------------------------------
USE SourceQA;

EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Account','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','PriceBook2','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','sbqq__Quote__c','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Contract','PKCHUNK'



--SELECT * INTO SourceNeocol.dbo.[sbqq__Subscription__c] FROM SourceQA.dbo.[sbqq__Subscription__c] WHERE 1=0;

---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Subscription_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.[Subscription_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select
	CAST('' AS nvarchar(18)) AS [ID]
	,CAST('' as nvarchar(2000)) as Error
	,Con.AccountId as AccountID
	,con.StartDate as ContractStartDate
	,con.EndDate as ContractEndDate
	,con.Status as ContractStatus
	,sub.SBQQ__Product__c as SBQQ__Product__c
	,sub.SBQQ__ProductOption__c as SBQQ__ProductOption__c
	,sub.SBQQ__SegmentEndDate__c as SBQQ__SegmentEndDate__c
	,sub.SBQQ__SegmentIndex__c as SBQQ__SegmentIndex__c
	,sub.SBQQ__SegmentKey__c as SBQQ__SegmentKey__c
	,sub.SBQQ__SegmentLabel__c as SBQQ__SegmentLabel__c
	,sub.SBQQ__SegmentQuantity__c as SBQQ__SegmentQuantity__c
	,sub.SBQQ__SegmentStartDate__c as SBQQ__SegmentStartDate__c
	,sub.SBQQ__SegmentUplift__c as SBQQ__SegmentUplift__c
	,sub.SBQQ__SegmentUpliftAmount__c as SBQQ__SegmentUpliftAmount__c


-- MIGRATION FIELDS 																						
	,concat(Con.ID,' - ',Sub.Id)  as Subscription_Migration_Id__c -- needs created on each object. Each object's field should be unique with the object name and migration_id__c at the end to avoid twin field issues. Field should be text, set to unique and external

into StageQA.dbo.[Subscription_Load]

FROM SourceQA.dbo.[SBQQ__Subscription__c] Sub
left join SourceQA.dbo.Contract Con
	on Sub.SBQQ__Contract__c = Con.Id
left join SourceQA.dbo.Product2 Prod
	on Prod.Id = Sub.SBQQ__Product__c
left join SourceQA.dbo.PriceBookEntry PBE
	on PBE.Product2Id = Prod.Id
	and PBE.CurrencyIsoCode = sub.CurrencyIsoCode
left join SourceQA.dbo.PriceBook2 PB
	on PB.Id = PBE.Product2Id

Where EndDate >= getdate()
and Status = 'Activated'

order by Con.ID,
		Sub.SBQQ__StartDate__c


---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE StageQA.dbo.[Subscription_Load]
ADD [Sort] int 
GO
WITH NumberedRows AS (
  SELECT *, ROW_NUMBER() OVER (ORDER BY AccountID) AS OrderRowNumber
  FROM StageQA.dbo.[Subscription_Load]
)
UPDATE NumberedRows
SET [Sort] = OrderRowNumber;
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Subscription_Load';


---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
select Subscription_Migration_Id__c, count(*)
from StageQA.dbo.[Subscription_Load]
group by Subscription_Migration_Id__c
having count(*) > 1

select *
 from StageQA.dbo.[Subscription_Load]


USE StageQA;

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

EXEC StageQA.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(50)','SANDBOX_QA','Subscription_Load'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------
-- Select * from Order_Load_Result
-- Select error, * from Order_Load_Result a where error not like '%success%'
--Select error, count(*) as num from Subscription_Load_Result a
--where error not like '%success%'
--group by error
--order by num desc

--Select error, * from Order_Load_Result a where error not like '%success%'
--Select top 100 error, * from Order_Load -- a where error like '%Opportunity must have%'



/* VIEW LOGS */
SELECT *
  FROM [StageQA].[dbo].[DBAmp_TableLoader_Perf]
  order by LogTime desc

