# Secret Server Reports

## Overview
RobOtters includes SQL report templates for monitoring simulated user activity directly within Secret Server's reporting interface.

## AD Group Setup
1. Create an AD group (e.g., SimulatedUsers) and add all simulated accounts as members
2. Sync the group into Secret Server: Admin > Active Directory > Synchronize Now

## Report Files
Report SQL files are in Data/Reports/:

| Report | File | Description |
|--------|------|-------------|
| User Activity Summary | ROUserActivity.sql | Per-user action counts and last-active timestamps (today, 7d, 30d) |
| Full Audit Trail | ROFullAuditTrail.sql | All secret, folder, and user audit events with date picker support |

## Creating a Report
1. In Secret Server, go to Admin > Reports > New Report
2. Set Category to User
3. Paste the contents of the SQL file (e.g., Data/Reports/ROUserActivity.sql)
4. Name the report (e.g., "Simulated User Activity")
5. Save and run

**Important:** Update the AD group name in each SQL file to match your group (default: SimulatedUsers).
