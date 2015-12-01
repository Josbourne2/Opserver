CREATE TABLE [dbo].[Mon_Job_History] (
    [id]          BIGINT           IDENTITY (1, 1) NOT NULL,
    [instance_id] INT              NULL,
    [job_id]      UNIQUEIDENTIFIER NULL,
    [status]      VARCHAR (10)     NULL,
    [volgnr]      BIGINT           NULL,
    [rundate]     DATE             NULL,
    [runtime]     TIME (7)         NULL,
    [runduration] CHAR (8)         NULL
);


GO
CREATE CLUSTERED INDEX [CIX_id]
    ON [dbo].[Mon_Job_History]([id] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_rundate]
    ON [dbo].[Mon_Job_History]([rundate] DESC, [runtime] ASC)
    INCLUDE([status], [job_id]);


GO
CREATE NONCLUSTERED INDEX [IX_status]
    ON [dbo].[Mon_Job_History]([status] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Volgnr]
    ON [dbo].[Mon_Job_History]([volgnr] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_volgnr_jobid_instanceid]
    ON [dbo].[Mon_Job_History]([volgnr] ASC, [job_id] ASC, [instance_id] ASC);

