CREATE TABLE [dbo].[Mon_Server_Freediskspace] (
    [ID]          INT           IDENTITY (1, 1) NOT NULL,
    [DriveLetter] CHAR (1)      NULL,
    [MBVrij]      INT           NOT NULL,
    [Datum]       SMALLDATETIME NOT NULL,
    [Instance_id] INT           NULL
);

