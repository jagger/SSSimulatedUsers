/*
    Secret Server Custom Report: Simulated User Full Audit Trail

    Combines secret, folder, and user audit events for all users in
    the SimZ AD group. Uses SS date parameters (#STARTDATE / #ENDDATE)
    for the built-in date picker.

    Setup:
      1. Create an AD group and add all sim accounts as members
      2. Sync the group into Secret Server via AD synchronization
      3. Create a new report in SS (Admin > Reports > New Report)
      4. Set Category to "User", paste this SQL, save
      5. Update the GroupName filter below to match your AD group name
*/

SELECT
    'Secret'                    AS AuditType,
    sm.DisplayName              AS Actor,
    sm.UserName                 AS Username,
    s.SecretName                AS Target,
    a.Action,
    a.Notes,
    a.DateRecorded              AS ActionDate,
    a.IpAddress
FROM tbAuditSecret a
INNER JOIN (
    SELECT u.UserId, u.UserName, u.DisplayName
    FROM tbUser u
    INNER JOIN tbUserGroup ug ON u.UserId   = ug.UserId
    INNER JOIN tbGroup g      ON ug.GroupId = g.GroupId
    WHERE g.GroupName = 'SimulatedUsers'
      AND u.Enabled = 1
) sm ON a.UserId = sm.UserId
INNER JOIN tbSecret s ON a.SecretId = s.SecretId
WHERE a.DateRecorded >= #STARTDATE
  AND a.DateRecorded <= #ENDDATE

UNION ALL

SELECT
    'Folder'                    AS AuditType,
    sm.DisplayName              AS Actor,
    sm.UserName                 AS Username,
    f.FolderName                AS Target,
    a.Action,
    a.Notes,
    a.DateRecorded              AS ActionDate,
    NULL                        AS IpAddress
FROM tbAuditFolder a
INNER JOIN (
    SELECT u.UserId, u.UserName, u.DisplayName
    FROM tbUser u
    INNER JOIN tbUserGroup ug ON u.UserId   = ug.UserId
    INNER JOIN tbGroup g      ON ug.GroupId = g.GroupId
    WHERE g.GroupName = 'SimulatedUsers'
      AND u.Enabled = 1
) sm ON a.UserId = sm.UserId
LEFT JOIN tbFolder f ON a.FolderId = f.FolderId
WHERE a.DateRecorded >= #STARTDATE
  AND a.DateRecorded <= #ENDDATE

UNION ALL

SELECT
    'User'                      AS AuditType,
    sm.DisplayName              AS Actor,
    sm.UserName                 AS Username,
    tu.DisplayName              AS Target,
    a.Action,
    a.Notes,
    a.DateRecorded              AS ActionDate,
    NULL                        AS IpAddress
FROM tbAuditUser a
INNER JOIN (
    SELECT u.UserId, u.UserName, u.DisplayName
    FROM tbUser u
    INNER JOIN tbUserGroup ug ON u.UserId   = ug.UserId
    INNER JOIN tbGroup g      ON ug.GroupId = g.GroupId
    WHERE g.GroupName = 'SimulatedUsers'
      AND u.Enabled = 1
) sm ON a.UserId = sm.UserId
INNER JOIN tbUser tu ON a.UserIdAffected = tu.UserId
WHERE a.DateRecorded >= #STARTDATE
  AND a.DateRecorded <= #ENDDATE
