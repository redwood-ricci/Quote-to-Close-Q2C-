---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: License Load Script	
--- Customer: Redwood
--- Primary Developer: Ajay 
--- Secondary Developers:  
--- Created Date: 11/25/2023
--- Last Updated: 
--- Change Log: 
--- Prerequisites:
--- 
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- Replicate Data
---------------------------------------------------------------------------------
USE [Source_Production_SALESFORCE];

EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','Account','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','Asset','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'SBQQ__Subscription__c','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'Contract' ,'PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'Product2','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','RW_Product_License_Component__c','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','RW_License_Component__c','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','RW_Component_License_Key__c','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','RW_Subscription_Instance__c','PKCHUNK'



---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'RW_Subscription_Instance__c_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.[RW_Subscription_Instance__c_Load]


---------------------------------------------------------------------------------
-- Create Staging Table for Subscription Instance
---------------------------------------------------------------------------------
Select
	CAST('' AS nvarchar(18)) AS [ID]
	,CAST('' as nvarchar(2000)) as Error
	,a.Id as External_Id__c
	,sub.Id as Subscription__c
	,(sub.CurrencyIsoCode) as CurrencyIsoCode
	,(prod.name) as ProductName
	,(prod.Id) as ProdId
	,(sub.SBQQ__StartDate__c) as StartDate
	,(sub.SBQQ__EndDate__c) as EndDate
	,(a.SerialNumber) as SerialNumber

into Stage_Production_SALESFORCE.dbo.[RW_Subscription_Instance__c_Load]

FROM Source_Production_SALESFORCE.dbo.Asset a
	left join Source_Production_SALESFORCE.dbo.Account acc
		on acc.Id = a.AccountId
	left join Source_Production_SALESFORCE.dbo.SBQQ__Subscription__c sub
		on sub.Id = a.Subscription2__c
	left join Source_Production_SALESFORCE.dbo.Contract con
		on con.Id = sub.SBQQ__Contract__c
	left join Source_Production_SALESFORCE.dbo.Product2 prod
		on prod.Id = sub.SBQQ__Product__c

WHERE con.EndDate > '2024-01-01'
	and con.Status = 'Activated'
	and acc.Test_Account__c = 'false'
	--and sub.sbqq__bundled__c = 'false'
	--and prod.IsActive = 'true'
	--and sub.SBQQ__ProductOption__c = NULL
	--and con.Id = '8003t000008OEHMAA4'
--group by sub.Id


select * from Stage_Production_SALESFORCE.dbo.[RW_Subscription_Instance__c_Load] where Subscription__c = 'a3I3t0000029EqdEAE'
select External_Id__c, count(*)
from Stage_Production_SALESFORCE.dbo.[RW_Subscription_Instance__c_Load]
group by External_Id__c
having count(*) > 1
---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(200)','Production_SALESFORCE','RW_Subscription_Instance__c_Load'


---------------------------------------------------------------------------------
-- Replicate Data
---------------------------------------------------------------------------------
USE Source_Production_SALESFORCE;

EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','RW_Subscription_Instance__c','PKCHUNK'

---------------------------------------------------------------------------------------------------------------------------------------------
-- Component License key Insert
---------------------------------------------------------------------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'RW_Component_License_Key__c_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.[RW_Component_License_Key__c_Load]

---------------------------------------------------------------------------------
-- Create Staging Table for Component License Key
---------------------------------------------------------------------------------
Select
	CAST('' AS nvarchar(18)) AS [ID]
	,CAST('' as nvarchar(2000)) as Error
	,left(max(Prod.Name), 80) as Name
	,max(a.Subscription2__c) as Subscription__c
	,max(PLC.Id) as Product_License_Component__c
	,max(LC.Name) as LicenseComponentName
	,max(PLC.Name) as ProductLicenseComponentName
	,max(a.SerialNumber) as License_Key__c
	,max(SI.Id) as Subscription_Instance__c
	--,max(sub.Name) as SubscriptionName
	,max(a.ContactId) as ContractNumber

into Stage_Production_SALESFORCE.dbo.[RW_Component_License_Key__c_Load]

FROM Source_Production_SALESFORCE.dbo.Asset a
	--inner join Source_Production_SALESFORCE.dbo.SBQQ__Subscription__c sub
	--	on sub.Id = a.Subscription2__c
	inner join Source_Production_SALESFORCE.dbo.RW_Subscription_Instance__c SI
		on SI.External_Id__c = a.Id
	inner join Source_Production_SALESFORCE.dbo.Product2 prod
		on prod.Product2Id = a.Product2Id
	left join Source_Production_SALESFORCE.dbo.RW_Product_License_Component__c PLC 
		on prod.Id = PLC.Product__c
	inner join Source_Production_SALESFORCE.dbo.RW_License_Component__c LC
		on LC.Id = PLC.License_Component__c
		and (prod.Name like (LC.Name+'%')
			or prod.Name = LC.Name)
	left join Source_Production_SALESFORCE.dbo.Contract con
		on con.Id = a.Contract__c
	left join Source_Production_SALESFORCE.dbo.Account acc
		on acc.Id = a.AccountId

WHERE con.EndDate > getdate()
	and con.Status = 'Activated'
	--and con.ContractNumber = '00003441'
	--and sub.Id = 'a3I3t000003SfGiEAK'
	and a.Subscription2__c is not null
	and acc.Test_Account__c = 'false'

group by a.Id

Order by max(Prod.Name)




---------------------------------------------------------------------------------
-- Validation
---------------------------------------------------------------------------------

select * from Stage_Production_SALESFORCE.dbo.[RW_Component_License_Key__c_Load] order by License_Key__c asc

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(200)','Production_SALESFORCE','RW_Component_License_Key__c_Load'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

Select error, * from RW_Component_License_Key__c_Load_Result a where error not like '%success%'
