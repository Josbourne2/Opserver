CREATE TABLE [dbo].[job_hist_backup] (
    [id]          BIGINT           IDENTITY (1, 1) NOT NULL,
    [instance_id] INT              NULL,
    [job_id]      UNIQUEIDENTIFIER NULL,
    [status]      VARCHAR (10)     NULL,
    [volgnr]      BIGINT           NULL,
    [rundate]     DATE             NULL,
    [runtime]     TIME (7)         NULL,
    [runduration] CHAR (8)         NULL
);

