<!--- getColumns.cfm --->
<cfheader name="Content-Type" value="application/json">
<cfif structKeyExists(form, "schema") AND structKeyExists(form, "table")>
    <cfquery name="getColumns" datasource="dashboard_portal">
        SELECT COLUMN_NAME, DATA_TYPE
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = <cfqueryparam value="#form.schema#" cfsqltype="cf_sql_varchar">
        AND TABLE_NAME = <cfqueryparam value="#form.table#" cfsqltype="cf_sql_varchar">
        ORDER BY ORDINAL_POSITION
    </cfquery>
    
    <!--- Convert query to array of structs for proper JSON formatting --->
    <cfset columnsArray = []>
    <cfloop query="getColumns">
        <cfset arrayAppend(columnsArray, {
            "COLUMN_NAME": COLUMN_NAME,
            "DATA_TYPE": DATA_TYPE
        })>
    </cfloop>
    
    <cfoutput>#serializeJSON(columnsArray)#</cfoutput>
<cfelse>
    <cfoutput>#serializeJSON({"error": "Missing required parameters"})#</cfoutput>
</cfif>