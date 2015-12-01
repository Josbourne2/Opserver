CREATE TABLE [dbo].[Mon_VerifiedLogins] (
    [account_name]      VARCHAR (255) NULL,
    [type]              VARCHAR (255) NULL,
    [privilege]         VARCHAR (255) NULL,
    [mapped_login_name] VARCHAR (255) NULL,
    [permission_path]   VARCHAR (255) NULL,
    [operator_notified] DATETIME2 (7) NULL,
    [verified_by_dba]   BIT           CONSTRAINT [DF_Mon_VerifiedLogins_verified_by_dba] DEFAULT ((0)) NOT NULL
);

