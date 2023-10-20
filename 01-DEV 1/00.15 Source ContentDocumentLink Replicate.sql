---------------------------------------------------------------------------------
-- Drop Source Table
---------------------------------------------------------------------------------
USE SourceQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'ContentDocumentLink' AND TABLE_SCHEMA = 'dbo')
DROP TABLE SourceQA.dbo.[ContentDocumentLink]

---------------------------------------------------------------------------------
--Create Table
---------------------------------------------------------------------------------


CREATE TABLE SourceQA.dbo.[ContentDocumentLink]
(
    [Id] NVARCHAR(MAX) NOT NULL,
    [LinkedEntityId] NVARCHAR(MAX) NOT NULL,
    [ContentDocumentId] NVARCHAR(MAX) NOT NULL,
    [IsDeleted] BIT NOT NULL,
    [SystemModstamp] DATETIME2 NOT NULL,
    [ShareType] NVARCHAR(MAX) NOT NULL,
    [Visibility] NVARCHAR(MAX) NOT NULL,

    -- Optionally, add a primary key constraint if needed
    -- PRIMARY KEY ([Id])
);

GO

-- Declare variables to hold data
DECLARE @ID nvarchar(18);
DECLARE @query NVARCHAR(MAX);

-- Declare a cursor to loop through the list of IDs
DECLARE ID_cursor CURSOR FOR
SELECT ID
FROM [SourceQA].dbo.Invoice__c;

-- Open the cursor
OPEN ID_cursor;

-- Loop through the cursor
FETCH NEXT FROM ID_cursor INTO @ID;
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Build the dynamic SQL query
    SET @query = 
    'INSERT INTO [SourceQA].dbo.[ContentDocumentLink]
    (
        [Id],
        [LinkedEntityId],
        [ContentDocumentId],
        [IsDeleted],
        [SystemModstamp],
        [ShareType],
        [Visibility]
    )
    SELECT 
        [Id],
        [LinkedEntityId],
        [ContentDocumentId],
        [IsDeleted],
        [SystemModstamp],
        [ShareType],
        [Visibility]
    FROM [SANDBOX_QA].[CData].[Salesforce].[ContentDocumentLink]
    WHERE LinkedEntityId = ''' + CAST(@ID AS NVARCHAR) + ''';';

    -- Execute the dynamic SQL query
    EXEC sp_executesql @query;

    -- Fetch the next ID
    FETCH NEXT FROM ID_cursor INTO @ID;
END;

-- Close and deallocate the cursor
CLOSE ID_cursor;
DEALLOCATE ID_cursor;
