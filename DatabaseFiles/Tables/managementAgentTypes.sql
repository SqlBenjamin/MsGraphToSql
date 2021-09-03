USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.managementAgentTypes

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.managementAgentTypes') IS NOT NULL
BEGIN
    DROP TABLE dbo.managementAgentTypes;
    PRINT 'Table "managementAgentTypes" Dropped';
END;
GO

-- Create Table:
CREATE TABLE dbo.managementAgentTypes ( managementAgentId int PRIMARY KEY CLUSTERED NOT NULL
                                       ,managementAgent nvarchar(35) NOT NULL
                                       ,managementAgentDescription nvarchar(2000) NOT NULL
                                       ) ON [PRIMARY];
GO
-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.managementAgentTypes') IS NOT NULL
PRINT 'Table "managementAgentTypes" Created';
GO

-- Populate the table:
DECLARE  @ErrorMessage  nvarchar(4000)
        ,@ErrorNumber   int;
BEGIN TRY
INSERT dbo.managementAgentTypes
VALUES  (1,N'eas',N'Not an MDM-enrolled device. This is the device that has a managed EAS mailbox setup on it. "The device is managed by Exchange server."')
       ,(2,N'mdm',N'Intune MDM is the only management authority. "The device is managed by Intune MDM."')
       ,(3,N'easMdm',N'Device is both MDM-managed by Intune and has an EAS managed mailbox. "The device is managed by both Exchange server and Intune MDM."')
       ,(4,N'intuneClient',N'Device is not MDM-managed, but instead managed by the Intune PC agent. "Intune client managed."')
       ,(5,N'easIntuneClient',N'Device is not MDM-managed, but instead managed by the Intune PC agent and has an EAS managed mailbox. "The device is EAS and Intune client dual managed."')
       ,(8,N'configurationManagerClient',N'Device is managed by SCCM. "The device is managed by Configuration Manager."')
       ,(10,N'configurationManagerClientMdm',N'Device is managed by SCCM and managed by Intune MDM channel. "The device is managed by Configuration Manager and MDM."')
       ,(11,N'configurationManagerClientMdmEas',N'Device is managed by SCCM and managed by Intune MDM channel and has an EAS managed mailbox. "The device is managed by Configuration Manager, MDM and Eas."')
       ,(16,N'unknown',N'Unknown managementAgent...no clue how this could happen.')
       ,(32,N'jamf',N'Device is managed by JAMF. "The device attributes are fetched from Jamf."')
       ,(64,N'googleCloudDevicePolicyController',N' Device is managed by Intune via the Google management agent (DPC). NOTE: "COSU" = Corp owned, single use.  Android Kiosk devices using the new Google cloud API method of enrollment. "The device is managed by Google''s CloudDPC."')
       ,(258,N'Microsoft365ManagedMdm',N'"This device is managed by Microsoft 365 through Intune."');
PRINT 'Table "managementAgentTypes" Populated';
END TRY
BEGIN CATCH
SELECT @ErrorMessage  = ERROR_MESSAGE()
      ,@ErrorNumber   = ERROR_NUMBER();
PRINT 'Error populating "managementAgentTypes"!';
PRINT N' *** Error Number: '+CONVERT(nvarchar(20),@ErrorNumber);
PRINT N' *** Error Message: '+@ErrorMessage;
END CATCH;
GO