<!--- getColumns.cfm --->
<cfif structKeyExists(form, "schema") AND structKeyExists(form, "table")>
    <cfquery name="getColumns" datasource="dashboard_portal">
        SELECT COLUMN_NAME, DATA_TYPE
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = <cfqueryparam value="#form.schema#" cfsqltype="cf_sql_varchar">
        AND TABLE_NAME = <cfqueryparam value="#form.table#" cfsqltype="cf_sql_varchar">
        ORDER BY ORDINAL_POSITION
    </cfquery>
    
    <cfcontent type="application/json">
    <cfoutput>#serializeJSON(getColumns)#</cfoutput>
<cfelse>
    <cfcontent type="application/json">
    <cfoutput>{"error": "Missing required parameters"}</cfoutput>
</cfif>