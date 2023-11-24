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
[RecordTypeId]='012O9000000AzF8IAK'
from StageQA.dbo.Account_Load A
WHERE ID in (
'0015000000oQydW',
'0013t00002fjCKs',
'0013t00002R1rM9',
'0013t00002StssL',
'0013t00002OUNHf',
'0013t00002Ttecp',
'0013t00002jMsoT',
'0013t00002UO8Rd',
'0013t00002N6b5K',
'0013t00002RaNHt',
'001Qn000001XeJ3',
'0013t00001U980S',
'0013t00002MOiZt',
'0013t00002N6h1G',
'0013t00002fjBh4',
'0013t00002UHiG6',
'0013t00002aP1kh',
'0013t00002jZzFM',
'0013800001R5RtH',
'0013t00002LzTAB',
'0013t00002MNEnn',
'0013t00002SYSTy',
'0013t00002UcDL0',
'0013t00002aFOYP',
'0015000000KA3AU',
'001Qn000003BOtK',
'0013t00002N6bmp',
'0013t00002h54xg',
'0013800001U8OSr',
'0013t00002kozKu',
'0013t00002UsjcW',
'0013t00002fRQTB',
'0013t00002Rbn5r',
'0013t00002N6bmr',
'0013t00002RdFw4',
'0013t00002TMN7B',
'0013t00002efBOR',
'0013800001MPknF',
'0013800001Ntquv',
'0013t00002IHaBf',
'0013t00002LzTGl',
'0013t00002N6aeX',
'0013t00002N6bmo',
'0013t00002N6bmq',
'0013t00002N6eFR',
'0013t00002Tv2p1',
'0013t00002aJAjB',
'0013t00002ehSi0',
'00150000014pFbP',
'0013800001MPYPt',
'0013800001NLKUS',
'0013800001R3IE5',
'0013800001S41Vb',
'0013800001U6eFc',
'0013800001U7IGv',
'0013800001U83q3',
'0013t00001riR7D',
'0013t00001riULq',
'0013t00001uJWGm',
'0013t000027Jr0j',
'0013t00002DWrK6',
'0013t00002LzTg3',
'0013t00002Mo3FI',
'0013t00002N5Nip',
'0013t00002N6cqp',
'0013t00002N6gEl',
'0013t00002N6ge3',
'0013t00002N6geG',
'0013t00002N6geH',
'0013t00002N6hKH',
'0013t00002N6iER',
'0013t00002OThKi',
'0013t00002PVwsT',
'0013t00002PWEbJ',
'0013t00002QdeXQ',
'0013t00002QdeY9',
'0013t00002QdeYA',
'0013t00002SsO8N',
'0013t00002SsUqB',
'0013t00002StovI',
'0013t00002Tj0Ij',
'0013t00002Tvghe',
'0013t00002TwGNP',
'0013t00002UDazm',
'0013t00002UDjFR',
'0013t00002UqMdU',
'0013t00002Ut2tE',
'0013t00002W4IUw',
'0013t00002XwTgX',
'0013t00002aFVah',
'0013t00002aogFJ',
'0013t00002bDkdk',
'0013t00002d8zys',
'0013t00002dm4MX',
'0013t00002dy5PA',
'0013t00002dyO7f',
'0013t00002e0czl',
'0013t00002e1hQD',
'0013t00002ee5VK',
'0013t00002efVqQ',
'0013t00002fOiH9',
'0013t00002fOjyy',
'0013t00002fRSfE',
'0013t00002fjBZT',
'0013t00002fjBvB',
'0013t00002fjC3f',
'0013t00002fjCPM',
'0013t00002fjCQA',
'0013t00002gHAkf',
'0013t00002gHBsn',
'0013t00002gHZRA',
'0013t00002jJywG',
'0015000000KA2GT',
'0015000000KA2VF',
'0015000000KA2jl',
'0015000000Kvuct',
'0015000000PABsp',
'0015000000PnqwX',
'0015000000VGqCT',
'0015000000bJ6LN',
'0015000000jP9vI',
'0015000000p9iBK',
'0015000000pAeXD',
'0015000000pAfVs',
'0013t00002cCv4p',
'0013t00002TLNg6',
'0013800001L2rE2AAJ',
'0013800001S4kmWAAR',
'0013t00001teHx8AAE',
'0013t00001zsXimAAE',
'0013t00001zsaCDAAY',
'0013t00002CQ6JlAAL',
'0013t00002N6b8ZAAR',
'0013t00002d6c5TAAQ',
'0013t00002dKUyjAAG',
'0013t00002edmX8AAI',
'0013t00002fRPjnAAG',
'0013t00002flgM8AAI',
'0013t00002fm0QrAAI',
'0013t00002gHEfSAAW',
'0013t00002h59atAAA',
'0013t00002hOLzbAAG',
'0013t00002iVpuNAAS',
'0013t00002iWa00AAC',
'0013t00002jMCynAAG',
'0013t00002jvN44AAE',
'0015000000KA2qbAAD',
'0015000000LLGXCAA5',
'0015000000MPoxcAAD',
'0015000000N61ovAAB',
'0015000000O8QuvAAF',
'0015000000PDNY7AAP',
'0015000000Q3BaVAAV',
'0015000000Q5liRAAR',
'0015000000Q6KeCAAV',
'0015000000c7PKbAAM',
'0015000000gHktVAAS'
)
​
update A set 
[RecordTypeId]='012O9000000AzF7IAK'
from StageQA.dbo.Account_Load A
where [RecordTypeId] is null
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