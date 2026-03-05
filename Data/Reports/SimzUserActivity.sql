/*
    Secret Server Custom Report: Simulated User Activity Summary

    Shows per-user action counts and last-active timestamps for all
    users in the designated SimZ AD group.

    Setup:
      1. Create an AD group and add all sim accounts as members
      2. Sync the group into Secret Server via AD synchronization
      3. Create a new report in SS (Admin > Reports > New Report)
      4. Set Category to "User", paste this SQL, save
      5. Update @GroupName below to match your AD group name
*/

DECLARE @GroupName NVARCHAR(256) = 'SimulatedUsers'

SELECT
    u.DisplayName                                   AS [User],
    u.UserName                                      AS [Username],
    COUNT(CASE WHEN a.DateRecorded >= CAST(GETDATE() AS DATE) THEN 1 END)
                                                     AS [Actions Today],
    COUNT(CASE WHEN a.DateRecorded >= DATEADD(DAY, -7, GETDATE()) THEN 1 END)
                                                     AS [Actions Last 7 Days],
    COUNT(CASE WHEN a.DateRecorded >= DATEADD(DAY, -30, GETDATE()) THEN 1 END)
                                                     AS [Actions Last 30 Days],
    MAX(a.DateRecorded)                              AS [Last Active],
    DATEDIFF(MINUTE, MAX(a.DateRecorded), GETDATE()) AS [Minutes Since Last Action]
FROM tbUser u
INNER JOIN tbUserGroup ug  ON ug.UserId  = u.UserId
INNER JOIN tbGroup g       ON g.GroupId  = ug.GroupId
LEFT  JOIN tbAuditSecret a ON a.UserId   = u.UserId
WHERE g.GroupName = @GroupName
  AND u.OrganizationId = 1
GROUP BY u.DisplayName, u.UserName
ORDER BY [Actions Last 7 Days] DESC
