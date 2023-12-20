---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Account UPDATE Script	
--- Customer: Redwood
--- Primary Developer: Jim Ziller
--- Secondary Developers:  Jim Ziller
--- Created Date: 10/11/2023
--- Last Updated: 
--- Change Log: 
--- 	
--- Prerequisites:
--- 1. 
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
USE SourceQA;
​
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Account'
-- EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'User'
--EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'RecordType'
​
---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;
​
​
if exists (select * from StageQA.INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Account_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.[Account_Load]
​
---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------
​
Select
	A.ID as Id,
	CAST('' as nvarchar(2000)) as Error,
-- MIGRATION FIELDS 																						
	A.ID + '-NEO' as Account_Migration_Id__c,
	BillingCountry
,BillingCountryCode
,Agreement_Contract_Payment_Terms__c
,SBQQ__RenewalPricingMethod__c
--,Id
,IsPartner
,Legal_Entity_Name__c
,[Name]
,Partner__c
,Partner_End_Date__c
,Partner_Product__c
,Partner_Start_Date__c
,Partner_Status__c
,Partner_Type__c
,Primary_Partner_Reseller__c
,RW_Partner_ID__c
,ShippingCountry
,ShippingCountryCode
,[Type]
,convert(varchar(50),Null) as [Record Type Name]
,convert(varchar(50),Null) as [RecordTypeId]
--,case when [Type] in ('BPA Customer','Customer','Former Customer','Prospect') then 'Account' 
--	  when [Type] in ('Consulting Services "Partner"','Reseller','Limited Reseller','MSP','System Integrator') then 'Partner Account' else 'Others' end as [Record Type Name]
--,case when [Type] in ('BPA Customer','Customer','Former Customer','Prospect') then '012E1000000MK89IAG' 
--	  when [Type] in ('Consulting Services "Partner"','Reseller','Limited Reseller','MSP','System Integrator') then '012E1000000MK9lIAG' else 'NA' end as [RecordTypeId]
INTO StageQA.dbo.Account_Load
FROM SourceQA.dbo.Account a
​
--select ID,Case_Safe_Account_ID__c,Customer_Status__c,X18_Digit_Account_ID__c FROM SourceQA.dbo.Account a
update A set 
[RecordTypeId]='012O9000000AzF8IAK', --Make sure to update this ID with the Production 'Partner Account' Record Type Id
[IsPartner]='true'
from StageQA.dbo.Account_Load A
WHERE ID in (
'0013800001L2rE2AAJ','0013800001MPYPtAAP','0013800001MPknFAAT','0013800001NLKUSAA5','0013800001NtquvAAB','0013800001R3IE5AAN','0013800001R5RtHAAV',
'0013800001S41VbAAJ','0013800001S4kmWAAR','0013800001U6eFcAAJ','0013800001U7IGvAAN','0013800001U83q3AAB','0013800001U8OSrAAN','0013t00001U980SAAR','0013t00001riR7DAAU',
'0013t00001riULqAAM','0013t00001teHx8AAE','0013t00001uJWGmAAO','0013t00001zsXimAAE','0013t00001zsaCDAAY','0013t000027Jr0jAAC','0013t00002CQ6JlAAL','0013t00002DWrK6AAL',
'0013t00002IHaBfAAL','0013t00002LzTABAA3','0013t00002LzTGlAAN','0013t00002LzTg3AAF','0013t00002MNEnnAAH','0013t00002MOiZtAAL','0013t00002Mo3FIAAZ','0013t00002N5NipAAF',
'0013t00002N6aeXAAR','0013t00002N6b5KAAR','0013t00002N6b8ZAAR','0013t00002N6bmoAAB','0013t00002N6bmpAAB','0013t00002N6bmqAAB','0013t00002N6bmrAAB','0013t00002N6cqpAAB',
'0013t00002N6eFRAAZ','0013t00002N6gElAAJ','0013t00002N6ge3AAB','0013t00002N6geGAAR','0013t00002N6geHAAR','0013t00002N6h1GAAR','0013t00002N6hKHAAZ','0013t00002N6iERAAZ',
'0013t00002OThKiAAL','0013t00002OUNHfAAP','0013t00002PVwsTAAT','0013t00002PWEbJAAX','0013t00002QdeXQAAZ','0013t00002QdeY9AAJ','0013t00002QdeYAAAZ','0013t00002R1rM9AAJ',
'0013t00002RaNHtAAN','0013t00002Rbn5rAAB','0013t00002RdFw4AAF','0013t00002SYSTyAAP','0013t00002SsO8NAAV','0013t00002SsUqBAAV','0013t00002StovIAAR','0013t00002StssLAAR',
'0013t00002TLNg6AAH','0013t00002TMN7BAAX','0013t00002Tj0IjAAJ','0013t00002TtecpAAB','0013t00002Tv2p1AAB','0013t00002TvgheAAB','0013t00002TwGNPAA3','0013t00002UDazmAAD',
'0013t00002UDjFRAA1','0013t00002UHiG6AAL','0013t00002UO8RdAAL','0013t00002UcDL0AAN','0013t00002UqMdUAAV','0013t00002UsjcWAAR','0013t00002Ut2tEAAR','0013t00002W4IUwAAN',
'0013t00002XwTgXAAV','0013t00002aFOYPAA4','0013t00002aFVahAAG','0013t00002aJAjBAAW','0013t00002aP1khAAC','0013t00002aogFJAAY','0013t00002bDkdkAAC','0013t00002cCv4pAAC',
'0013t00002d6c5TAAQ','0013t00002d8zysAAA','0013t00002dKUyjAAG','0013t00002dm4MXAAY','0013t00002dy5PAAAY','0013t00002dyO7fAAE','0013t00002e0czlAAA','0013t00002e1hQDAAY',
'0013t00002edmX8AAI','0013t00002ee5VKAAY','0013t00002efBORAA2','0013t00002efVqQAAU','0013t00002ehSi0AAE','0013t00002fOiH9AAK','0013t00002fOjyyAAC','0013t00002fRPjnAAG',
'0013t00002fRQTBAA4','0013t00002fRSfEAAW','0013t00002fjBZTAA2','0013t00002fjBh4AAE','0013t00002fjBvBAAU','0013t00002fjC3fAAE','0013t00002fjCKsAAM','0013t00002fjCPMAA2',
'0013t00002fjCQAAA2','0013t00002flgM8AAI','0013t00002fm0QrAAI','0013t00002gHAkfAAG','0013t00002gHBsnAAG','0013t00002gHEfSAAW','0013t00002gHZRAAA4','0013t00002h54xgAAA',
'0013t00002h59atAAA','0013t00002hOLzbAAG','0013t00002iVpuNAAS','0013t00002iWa00AAC','0013t00002jJywGAAS','0013t00002jMCynAAG','0013t00002jMsoTAAS','0013t00002jZzFMAA0',
'0013t00002jvN44AAE','0013t00002kozKuAAI','0015000000KA2GTAA1','0015000000KA2VFAA1','0015000000KA2jlAAD','0015000000KA2qbAAD','0015000000KA3AUAA1','0015000000KvuctAAB',
'0015000000LLGXCAA5','0015000000MPoxcAAD','0015000000N61ovAAB','0015000000O8QuvAAF','0015000000PABspAAH','0015000000PDNY7AAP','0015000000PnqwXAAR','0015000000Q3BaVAAV',
'0015000000Q5liRAAR','0015000000Q6KeCAAV','0015000000VGqCTAA1','0015000000bJ6LNAA0','0015000000c7PKbAAM','0015000000gHktVAAS','0015000000jP9vIAAS','0015000000oQydWAAS',
'0015000000p9iBKAAY','0015000000pAeXDAA0','0015000000pAfVsAAK','00150000014pFbPAAU','0013t00002N6ihqAAB','0013t00002N6gPsAAJ','0013t00002N6ihoAAB','0013t00002N6ge1AAB',
'0013t00002gHNq9AAG','0013t00002N6geHAAR','0013t00002dL64XAAS','0013t00001riR7DAAU','0013t00002N6ge3AAB'
)
​
update A set 
[RecordTypeId]='012O9000000AzF7IAK' --Make sure to update this ID with the Production 'Account' Record Type Id
from StageQA.dbo.Account_Load A
where [RecordTypeId] is null

update A set
[Agreement_Contract_Payment_Terms__c] = 'Net 30'
from StageQA.dbo.Account_Load A
where [Agreement_Contract_Payment_Terms__c] is null

update A set
[SBQQ__RenewalPricingMethod__c] = 'Uplift'
from StageQA.dbo.Account_Load A
where [SBQQ__RenewalPricingMethod__c] != 'Uplift'
​
--select * from StageQA.dbo.Account_Load A
​
-- Surgical Filters to make sure each update doesn't go beyond the scope of the update
	
---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE StageQA.dbo.[Account_Load]
ADD [Sort] int IDENTITY (1,1)
​
​
---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
​
select Account_Migration_Id__c, count(*)
from StageQA.dbo.Account_Load
group by Account_Migration_Id__c
having count(*) > 1


select *
 from StageQA.dbo.Account_Load
​
---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
​
EXEC StageQA.dbo.SF_Tableloader 'UPDATE:bulkapi,batchsize(100)','SANDBOX_QA','Account_Load'
​
---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------
​
-- Select error, * from StageQA.dbo.Account_Load_Result a where error not like '%success%'