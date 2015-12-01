CREATE TABLE [dbo].[mon_jobs] (
    [id]               INT              IDENTITY (1, 1) NOT NULL,
    [instance_id]      INT              NULL,
    [job_id]           UNIQUEIDENTIFIER NULL,
    [jobname]          VARCHAR (200)    NULL,
    [job_enabled]      BIT              NULL,
    [schedule_id]      INT              NULL,
    [schedule_name]    VARCHAR (300)    NULL,
    [schedule_enabled] BIT              NULL,
    [owner]            VARCHAR (100)    NULL,
    [crdate]           SMALLDATETIME    NULL,
    [updatedate]       SMALLDATETIME    NULL,
    [deldate]          SMALLDATETIME    NULL
);


GO
CREATE CLUSTERED INDEX [CIX_iid_id]
    ON [dbo].[mon_jobs]([instance_id] ASC, [job_id] ASC);

