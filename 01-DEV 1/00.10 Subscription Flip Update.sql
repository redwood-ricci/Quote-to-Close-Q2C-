---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Subscription Load Script	
--- Customer: Redwood
--- Primary Developer: Ajay Santhosh
--- Secondary Developers:  
--- Created Date: 15/12/2023
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

EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Product2','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Contract','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'SBQQ__Subscription__c','PKCHUNK'


---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'SBQQ__Subscription__c_FlipLoad' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.SBQQ__Subscription__c_FlipLoad

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------
USE StageQA;

WITH Flip_Product as (
	Select Id, Name 
		from SourceQA.dbo.Product2 
		where Name like '%flip%'
),
Contract_Ids as (
	Select 
		MIN(Sub.SBQQ__Contract__c) as ConId, 
		MIN(Con.ContractNumber) as ContractNumber,
		MIN(Con.EndDate) as EndDate,
		SUM(Sub.SBQQ__CustomerPrice__c) as CustomerPrice
		from SourceQA.dbo.SBQQ__Subscription__c Sub
		inner join Flip_Product FP
			on FP.Id = Sub.Sbqq__Product__c
		inner join SourceQA.dbo.Contract Con
			on Sub.SBQQ__Contract__c = Con.Id
		where Con.EndDate > getDate() 
	group by Con.Id
),
Subs_Excluding_Flip_Products as (
	select Count(*) as SubCount, Con.ConId as ConId, MIN(Sub.Id) as SubId
		from SourceQA.dbo.SBQQ__Subscription__c Sub
			inner join Contract_Ids Con
				on Con.ConId = Sub.SBQQ__Contract__c
		where Sub.SBQQ__Product__c not in (select Id from Flip_Product)
			and Sub.SBQQ__CustomerPrice__c = 0
		group by Con.ConId
)
--- Total amount of Flip value
--- Number of subscriptions per contract excluding Flip products and Subscription lines having more than 0$ value
select 
	Sub.Id as Id,
	Con.Id as REF_ContractId,
	Prod.Name as REF_ProductName,
	Con.ContractNumber as REF_ContractNumber,
	Sub.Net_Total__c as REF_Net_Total__c,
	Sub.SBQQ__ListPrice__c as REF_SBQQ__ListPrice__c,
	Sub.SBQQ__NetPrice__c as REF_SBQQ__NetPrice__c,
	(ConIds.CustomerPrice/SubXFlipProd.SubCount) as SBQQ__CustomerPrice__c

	into StageQA.dbo.SBQQ__Subscription__c_FlipLoad

	from SourceQA.dbo.SBQQ__Subscription__c Sub
		inner join Contract_Ids ConIds
			on ConIds.ConId = Sub.sbqq__Contract__c
		inner join Subs_Excluding_Flip_Products SubXFlipProd
			on SubXFlipProd.ConId = Sub.SBQQ__Contract__c
		inner join SourceQA.dbo.Contract as Con
			on Con.Id = Sub.SBQQ__Contract__c
		inner join SourceQA.dbo.Product2 Prod
			on Prod.Id = Sub.SBQQ__Product__c
	where Sub.SBQQ__Product__c not in (select Id from Flip_Product) 
		and Sub.SBQQ__CustomerPrice__c = 0

select * from StageQA.dbo.SBQQ__Subscription__c_FlipLoad where REF_ContractId = '8003t000008aTGZAA2'





---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------