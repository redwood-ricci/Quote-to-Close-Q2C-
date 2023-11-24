---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Product Insert
--- Customer: Redwood
--- Primary Developer: Ajay Santhosh
--- Secondary Developers:  
--- Created Date: 17/11/2023
--- Last Updated: 
--- Change Log: 
--- 	
--- Prerequisites:
--- 1. 
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- Replicate Data
---------------------------------------------------------------------------------
USE SourceNeocol

EXEC SourceNeocol.dbo.SF_Replicate 'SANDBOX_NEOCOL','Product2','PKCHUNK'

USE SourceQA

EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Product2','PKCHUNK'
---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Product2_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.[Product2_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select
	Prod.*
	,Prod_QA.Id as ProdId
	,CAST('' as nvarchar(2000)) as Error
	--,Prod.Id as External_Id__c

INTO StageQA.dbo.Product2_Load

FROM SourceNeocol.dbo.Product2 Prod
	left join SourceQA.dbo.Product2 Prod_QA
		on Prod.Id = Prod_QA.External_Id__c

WHERE Prod.Id in ('01tE1000000snWzIAI','01tE1000000YnHhIAK','01tE1000000srLyIAI','01tE1000000sk4LIAQ','01tE1000000snXLIAY','01tE1000000spyaIAA','01tE1000000snWvIAI','01tE1000000YnI7IAK','01tE1000000sn0WIAQ','01tE1000000sn0XIAQ','01tE1000000sovuIAA','01tE1000000YnHvIAK','01tE1000000sk4PIAQ','01tE1000000YpbCIAS','01tE1000000srM7IAI','01tE1000000snXFIAY','01tE1000000vtW2IAI','01tE1000000YpbFIAS','01tE1000000snXSIAY','01tE1000000sn08IAA','01tE1000000sn0CIAQ','01tE1000000vwQfIAI','01tE1000000sn0OIAQ','01tE1000000spyPIAQ','01tE1000001jmWAIAY','01tE1000000srLzIAI','01tE1000001judOIAQ','01tE1000000srMBIAY','01tE1000000sn0UIAQ','01tE1000000YnHjIAK','01tE1000000snWnIAI','01tE1000000YnI3IAK','01tE1000000vuLdIAI','01tE1000000srM1IAI','01tE1000000spybIAA','01tE1000000sovwIAA','01tE1000000vuiDIAQ','01tE1000000snXQIAY','01tE1000000sow0IAA','01tE1000000YnHoIAK','01tE1000000YnHuIAK','01tE1000000snWpIAI','01tE1000000snWxIAI','01tE1000000vuDZIAY','01tE1000000snXHIAY','01tE1000000vxPxIAI','01tE1000000sn0FIAQ','01tE1000000snWwIAI','01tE1000000YnHiIAK','01tE1000000YnHrIAK','01tE1000000YnHpIAK','01tE10000014ihyIAA','01tE1000000snXTIAY','01tE1000000snWtIAI','01tE1000000vucXIAQ','01tE1000001jwiPIAQ','01tE1000000srLwIAI','01tE1000000YnI4IAK','01tE1000000YnHsIAK','01tE1000000sn0HIAQ','01tE1000000sn0aIAA','01tE1000000sn0cIAA','01tE1000000snXEIAY','01tE1000000sn07IAA','01tE1000000spyeIAA','01tE1000000srMAIAY','01tE1000000vsV7IAI','01tE1000000YnHzIAK','01tE1000000snXBIAY','01tE1000000snXGIAY','01tE1000000spyXIAQ','01tE1000000sn0dIAA','01tE1000000sk4NIAQ','01tE1000000srM5IAI','01tE1000000sn05IAA','01tE1000000srLxIAI','01tE1000000YnHnIAK','01tE1000000sn0KIAQ','01tE1000000snWrIAI','01tE1000000snWuIAI','01tE1000000snX0IAI','01tE1000000snXNIAY','01tE1000000sn0YIAQ','01tE1000000snWqIAI','01tE1000000snXKIAY','01tE1000000sn0MIAQ','01tE1000000sn0SIAQ','01tE1000000snXAIAY','01tE1000000snX9IAI','01tE1000000snXCIAY','01tE1000000sn0TIAQ','01tE1000000snXDIAY','01tE1000000snXJIAY','01tE1000000spySIAQ','01tE1000000sn0BIAQ','01tE1000000YpbEIAS','01tE1000000YnHmIAK','01tE1000000sn0GIAQ','01tE1000000sovvIAA','01tE1000000sow1IAA','01tE1000000sn09IAA','01tE1000000vuVJIAY','01tE1000000spyWIAQ','01tE1000000snXIIAY','01tE1000000spydIAA','01tE1000000sk4OIAQ','01tE1000000vpYrIAI','01tE1000000snX3IAI','01tE1000000srLvIAI','01tE1000000sn0VIAQ','01tE1000000snX4IAI','01tE1000000snXRIAY','01tE1000000spycIAA','01tE1000000srM2IAI','01tE1000001jx1lIAA','01tE1000000YnI0IAK','01tE1000000sn0AIAQ','01tE1000000sn0bIAA','01tE1000000snXUIAY','01tE1000000YnI1IAK','01tE1000000sn0ZIAQ','01tE1000000sow2IAA','01tE1000000sn0EIAQ','01tE1000000sqBJIAY','01tE10000014hKNIAY','01tE1000000YnHyIAK','01tE1000000spyTIAQ','01tE1000000YnI2IAK','01tE1000000sn0JIAQ','01tE1000000sn0PIAQ','01tE1000000snX6IAI','01tE1000000YpbDIAS','01tE1000000vrZ6IAI','01tE1000000snX5IAI','01tE1000000spyQIAQ','01tE1000000spyhIAA','01tE1000000sn06IAA','01tE1000000srM6IAI','01tE1000000snX8IAI','01tE1000000sn0RIAQ','01tE1000000sn0eIAA','01tE1000000snWsIAI','01tE1000000snWyIAI','01tE1000000vr61IAA','01tE1000000sn0LIAQ','01tE1000000snWoIAI','01tE1000000YnHxIAK','01tE1000000sn0DIAQ','01tE1000000srM9IAI','01tE1000000spyZIAQ','01tE1000000sovzIAA','01tE1000000YnHkIAK','01tE1000000sqBKIAY','01tE1000000spyUIAQ','01tE1000000snXMIAY','01tE1000000spygIAA','01tE1000000srLtIAI','01tE1000000sn0QIAQ','01tE1000000srM3IAI','01tE1000000sn0IIAQ','01tE1000000vudNIAQ','01tE1000000YnHlIAK','01tE1000000spyfIAA','01tE1000000srM0IAI','01tE1000000sn0NIAQ','01tE1000000snX1IAI','01tE1000000spyRIAQ','01tE1000000snXOIAY','01tE1000000srM8IAI','01tE1000000vt4bIAA','01tE1000000snXPIAY','01tE1000000YnHtIAK','01tE1000000snX2IAI','01tE1000000srLuIAI','01tE1000000sovxIAA','01tE1000000snX7IAI','01tE1000000spyiIAA','01tE1000000YnI6IAK','01tE1000000sk4MIAQ','01tE1000000YnHqIAK','01tE1000000spyYIAQ','01tE1000000YnHwIAK','01tE1000000srM4IAI','01tE1000000YnI5IAK','01tE1000000sovyIAA')
	and Prod.IsActive = 'true'
	and Prod.Name not in ('Test Bundle', 'Test Product')
	
---------------------------------------------------------------------------------
--Drop Id from the Column
ALTER TABLE StageQA.dbo.Product2_Load
DROP COLUMN Id, ExternalId, LastModifiedById, LastModifiedDate, CreatedDate, CreatedById;

EXEC sp_rename 'StageQA.dbo.Product2_Load.ProdId', 'Id';
--ALTER TABLE StageQA.dbo.Product2_Load
--ADD Id nchar(18);
---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
Select * from StageQA.dbo.Product2_Load


---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE StageQA;

EXEC StageQA.dbo.SF_Tableloader 'UPDATE:bulkapi,batchsize(100)','SANDBOX_QA','Product2_Load'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------
Select error, count(*) as num from Product2_Load_Result a
where error not like '%success%'
group by error
order by num desc

