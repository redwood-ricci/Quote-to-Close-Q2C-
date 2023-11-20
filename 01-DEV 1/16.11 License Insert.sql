---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: License Load Script	
--- Customer: Redwood
--- Primary Developer: Michael 
--- Secondary Developers:  Ajay
--- Created Date: 10/16/2023
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
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Asset','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'SBQQ__Subscription__c','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Contract' ,'PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Product2','PKCHUNK'

USE SourceNeocol

EXEC SourceNeocol.dbo.SF_Replicate 'SANDBOX_NEOCOL','RW_Product_License_Component__c','PKCHUNK'
EXEC SourceNeocol.dbo.SF_Replicate 'SANDBOX_NEOCOL','RW_Component_License_Key__c','PKCHUNK'
EXEC SourceNeocol.dbo.SF_Replicate 'SANDBOX_NEOCOL','RW_Subscription_Instance__c','PKCHUNK'


---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'SubscriptionInstance_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.[SubscriptionInstance_Load]

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'ComponentLicenseKey_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.[ComponentLicenseKey_Load]

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'ProductLicenseComponent_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.[ProductLicenseComponent_Load]

---------------------------------------------------------------------------------
-- Create Staging Table for Subscription Instance
---------------------------------------------------------------------------------
Select top 100
	CAST('' AS nvarchar(18)) AS [ID]
	,CAST('' as nvarchar(2000)) as Error
	,a.Subscription__c as Subscription__c
	,prod.name as ProductName
	,sub.SBQQ__StartDate__c as StartDate
	,a.SerialNumber as SerialNumber

into StageQA.dbo.[SubscriptionInstance_Load]

FROM SourceQA.dbo.Asset a
	left join SourceQA.dbo.Account acc
		on acc.Id = a.AccountId
	left join SourceQA.dbo.SBQQ__Subscription__c sub
		on sub.Id = a.Subscription__c
	left join SourceQA.dbo.Contract con
		on con.Id = sub.SBQQ__Contract__c
	left join SourceQA.dbo.Product2 prod
		on prod.Id = sub.SBQQ__Product__c

WHERE sub.SBQQ__EndDate__c > getdate()
	and con.Status = 'Activated'
	and acc.Test_Account__c = 'false'
	and sub.sbqq__bundled__c = 'false'
	and prod.IsActive = 'true'
	--and sub.SBQQ__ProductOption__c = NULL
	--and con.Id = '8003t000008OEHMAA4'



select * from StageQA.dbo.[SubscriptionInstance_Load]

---------------------------------------------------------------------------------
-- Create Staging Table for Component License Key
---------------------------------------------------------------------------------
Select
	CAST('' AS nvarchar(18)) AS [ID]
	,CAST('' as nvarchar(2000)) as Error
	,a.Subscription__c as Subscription__c

into StageQA.dbo.[SubscriptionInstance_Load]

FROM SourceQA.dbo.Asset a
	left join SourceQA.dbo.Account acc
		on acc.Id = a.AccountId
	left join SourceQA.dbo.SBQQ__Subscription__c sub
		on sub.Id = a.Subscription__c
	left join SourceQA.dbo.Contract con
		on con.Id = sub.SBQQ__Contract__c
	left join SourceQA.dbo.Product2 prod
		on prod.Id = sub.SBQQ__Product__c

WHERE sub.SBQQ__EndDate__c > getdate()
	and con.Status = 'Activated'
	and Acct.Test_Account__c = 'false'
	and sub.sbqq__bundled__c = 'false'
	and sub.SBQQ__ProductOption__c = NULL

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

