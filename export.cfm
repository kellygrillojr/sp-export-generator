<cfinclude template="../includes/header.cfm">
<!--- export.cfm --->
<cfoutput>
<!DOCTYPE html>
<html>
<head>
    <title>Export SP Generator</title>
    <style>
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        .step { margin-bottom: 20px; padding: 15px; border: 1px solid ##ccc; }
        .selected-columns { list-style: none; padding: 0; }
        .selected-columns li { padding: 5px; margin: 2px 0; background: ##f5f5f5; cursor: move; }
    .multiple-select {
        border: 1px solid ##ccc;
        border-radius: 4px;
        padding: 5px;
    }
    .multiple-select option {
        padding: 5px;
    }
    .multiple-select option:hover {
        background-color: ##f0f0f0;
    }
    </style>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/Sortable/1.14.0/Sortable.min.js"></script>
</head>
<body>
<div class="container">
    <h1>Export Stored Procedure Generator</h1>

    <!--- Step 1: Schema Selection --->
    <div class="step">
        <h2>Step 1: Select Schema</h2>
        <cfquery name="getSchemas" datasource="dashboard_portal">
            SELECT SCHEMA_NAME 
            FROM INFORMATION_SCHEMA.SCHEMATA 
            WHERE SCHEMA_NAME NOT IN ('information_schema', 'sys', 'mysql')
            ORDER BY SCHEMA_NAME
        </cfquery>
        
        <form action="export1.cfm" method="post">
            <select name="selectedSchema" onchange="this.form.submit()">
                <option value="">Select Schema</option>
                <cfloop query="getSchemas">
                    <option value="#SCHEMA_NAME#" <cfif structKeyExists(form, "selectedSchema") && form.selectedSchema eq SCHEMA_NAME>selected</cfif>>#SCHEMA_NAME#</option>
                </cfloop>
            </select>
        </form>
    </div>

    <!--- Step 2: Table Selection --->
    <cfif structKeyExists(form, "selectedSchema")>
    <div class="step">
        <h2>Step 2: Select Tables</h2>
        <cfquery name="getTables" datasource="dashboard_portal">
            SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = <cfqueryparam value="#form.selectedSchema#" cfsqltype="cf_sql_varchar">
            ORDER BY TABLE_NAME, ORDINAL_POSITION
        </cfquery>

        <form action="export1.cfm" method="post" id="tableForm">
            <input type="hidden" name="selectedSchema" value="#form.selectedSchema#">
            <select name="selectedTables[]" multiple size="10" style="width: 300px; height: 200px;" class="multiple-select">
                <cfset prevTable = "">
                <cfloop query="getTables">
                    <cfif prevTable neq TABLE_NAME>
                        <option value="#TABLE_NAME#">#TABLE_NAME#</option>
                        <cfset prevTable = TABLE_NAME>
                    </cfif>
                </cfloop>
            </select>
            <br>
            <small>Hold Ctrl (Windows) or Cmd (Mac) to select multiple tables</small>
            <br><br>
            <button type="button" onclick="showJoinBuilder()">Next: Configure Joins</button>
        </form>
    </div>

        <!--- Step 3: Join Configuration --->
        <div class="step" id="joinBuilder" style="display: none;">
            <h2>Step 3: Configure Joins</h2>
            <div id="joinConfig">
                <!-- Join configuration will be populated dynamically -->
            </div>
            <button type="button" onclick="showColumnSelector()">Next: Select Columns</button>
        </div>

        <!--- Step 4: Column Selection --->
        <div class="step" id="columnSelector" style="display: none;">
            <h2>Step 4: Select and Order Columns</h2>
            <div id="availableColumns"></div>
            <ul id="selectedColumns" class="selected-columns">
                <!-- Selected columns will be sortable -->
            </ul>
        </div>

        <!--- Step 5: Export Configuration --->
        <div class="step" id="exportConfig" style="display: none;">
            <h2>Step 5: Export Configuration</h2>
            <form id="finalConfig">
                <label>Export File Path:</label>
                <input type="text" name="exportPath" placeholder="e.g., /exports/{schema}/data.csv">
                <button type="button" onclick="generateStoredProcedure()">Generate Stored Procedure</button>
            </form>
        </div>

        <!--- Result Output --->
        <div class="step" id="resultOutput" style="display: none;">
            <h2>Generated Stored Procedure</h2>
            <textarea id="spScript" rows="20" style="width: 100%;"></textarea>
            <button onclick="copyToClipboard()">Copy to Clipboard</button>
        </div>
    </cfif>
</div>

<script>
// JavaScript functions for handling the UI interactions
function showJoinBuilder() {
    const selectedTables = Array.from(document.querySelector('select[name="selectedTables"]').selectedOptions)
        .map(option => option.value);
    
    if (selectedTables.length < 1) {
        alert('Please select at least one table');
        return;
    }

    document.getElementById('joinBuilder').style.display = 'block';
    buildJoinInterface(selectedTables);
}

function buildJoinInterface(tables) {
    const joinConfig = document.getElementById('joinConfig');
    joinConfig.innerHTML = '';

    if (tables.length === 1) {
        joinConfig.innerHTML = '<p>No joins needed for single table.</p>';
        return;
    }

    // Build join configuration interface
    let html = '<div class="joins">';
    for (let i = 1; i < tables.length; i++) {
        html += `
            <div class="join-row">
                <select name="joinType${i}">
                    <option value="INNER JOIN">INNER JOIN</option>
                    <option value="LEFT JOIN">LEFT JOIN</option>
                    <option value="RIGHT JOIN">RIGHT JOIN</option>
                </select>
                ${tables[i]} ON
                <select name="leftColumn${i}">
                    <option>Loading columns...</option>
                </select>
                =
                <select name="rightColumn${i}">
                    <option>Loading columns...</option>
                </select>
            </div>
        `;
    }
    html += '</div>';
    joinConfig.innerHTML = html;

    // Load columns for join configuration
    loadTableColumns();
}

function loadTableColumns() {
    // This would make an AJAX call to get columns for selected tables
    // For demo, we'll use a placeholder
    console.log('Loading columns...');
}

function showColumnSelector() {
    document.getElementById('columnSelector').style.display = 'block';
    document.getElementById('exportConfig').style.display = 'block';
    loadAvailableColumns();
}

function loadAvailableColumns() {
    // This would make an AJAX call to get all available columns
    // For demo, we'll use a placeholder
    console.log('Loading available columns...');
}

// Initialize column sorting
new Sortable(document.getElementById('selectedColumns'), {
    animation: 150,
    ghostClass: 'sortable-ghost'
});

function generateStoredProcedure() {
    // Gather all configuration
    const config = {
        schema: document.querySelector('select[name="selectedSchema"]').value,
        tables: Array.from(document.querySelector('select[name="selectedTables"]').selectedOptions)
            .map(option => option.value),
        joins: gatherJoinConfig(),
        columns: Array.from(document.getElementById('selectedColumns').children)
            .map(li => li.dataset.column),
        exportPath: document.querySelector('input[name="exportPath"]').value
    };

    // Generate the stored procedure script
    const script = generateSPScript(config);
    
    // Display the result
    document.getElementById('resultOutput').style.display = 'block';
    document.getElementById('spScript').value = script;
}

function generateSPScript(config) {
    const procedureName = `sp_export_${config.schema}_${config.tables[0]}`;
    
    let script = `
CREATE PROCEDURE ${procedureName}
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @filepath VARCHAR(500) = '${config.exportPath}';
    DECLARE @sql NVARCHAR(MAX);

    SET @sql = 'SELECT ';
    ${config.columns.map(col => `    @sql += '${col}, ';`).join('\n')}
    SET @sql = LEFT(@sql, LEN(@sql) - 1);
    
    SET @sql += ' FROM ${config.tables[0]} ';
    ${config.joins.map(join => `    SET @sql += '${join}';`).join('\n')}

    -- Export to CSV using BCP
    DECLARE @bcpCommand VARCHAR(2000);
    SET @bcpCommand = 'bcp "' + @sql + '" queryout "' + @filepath + 
        '" -c -t, -T -S ' + @@SERVERNAME;

    EXEC xp_cmdshell @bcpCommand;
END;
    `;

    return script;
}

function copyToClipboard() {
    const spScript = document.getElementById('spScript');
    spScript.select();
    document.execCommand('copy');
}
</script>
</cfoutput>
<cfinclude template="../includes/footer.cfm">