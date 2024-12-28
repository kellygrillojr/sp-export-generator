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
        /* Join configuration styles */
        .join-row {
            margin: 15px 0;
            padding: 15px;
            background: ##f9f9f9;
            border: 1px solid ##ddd;
            border-radius: 4px;
        }
        .join-type {
            padding: 5px;
            margin-right: 10px;
            min-width: 120px;
        }
        .column-select {
            padding: 5px;
            margin: 0 10px;
            min-width: 200px;
        }
        .table-name {
            font-weight: bold;
            color: ##444;
            padding: 5px;
            background: ##eee;
            border-radius: 3px;
            margin: 0 5px;
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
        
        <form action="export.cfm" method="post">
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

            <form action="export.cfm" method="post" id="tableForm">
                <input type="hidden" name="selectedSchema" value="#form.selectedSchema#">
                <select name="selectedTables" multiple size="10" style="width: 300px; height: 200px;" class="multiple-select">
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
    console.log('showJoinBuilder called');
    const tableSelect = document.querySelector('select[name="selectedTables"]');
    console.log('Selected tables:', tableSelect);
    
    if (!tableSelect) {
        console.error('Table select element not found');
        return;
    }

    const selectedTables = Array.from(tableSelect.selectedOptions)
        .map(option => option.value);
    
    console.log('Selected tables:', selectedTables);
    
    if (selectedTables.length < 1) {
        alert('Please select at least one table');
        return;
    }

    document.getElementById('joinBuilder').style.display = 'block';
    buildJoinInterface(selectedTables);
}

function buildJoinInterface(tables) {
    console.log('Building join interface for tables:', tables);
    const joinConfig = document.getElementById('joinConfig');
    joinConfig.innerHTML = '';

    if (tables.length === 1) {
        joinConfig.innerHTML = '<p>No joins needed for single table.</p>';
        return;
    }

    // Build join configuration interface
    let html = '<div class="joins">';
    for (let i = 1; i < tables.length; i++) {
        const baseTable = tables[0]; // Always use the first table as the base
        const joinTable = tables[i];
        
        html += `
            <div class="join-row">
                <div style="margin-bottom: 10px;">
                    <select name="joinType${i}" class="join-type">
                        <option value="INNER JOIN">INNER JOIN</option>
                        <option value="LEFT JOIN">LEFT JOIN</option>
                        <option value="RIGHT JOIN">RIGHT JOIN</option>
                    </select>
                </div>
                <div style="margin-bottom: 10px;">
                    <span class="table-name">${baseTable}</span>
                    <select name="leftColumn${i}" class="column-select">
                        <option>Loading columns...</option>
                    </select>
                    =
                    <span class="table-name">${joinTable}</span>
                    <select name="rightColumn${i}" class="column-select">
                        <option>Loading columns...</option>
                    </select>
                </div>
            </div>
        `;
    }
    html += '</div>';
    joinConfig.innerHTML = html;

    // Load columns for join configuration
    loadAllTableColumns(tables);
}

async function loadAllTableColumns(tables) {
    const schema = document.querySelector('select[name="selectedSchema"]').value;
    const columnData = {};
    
    // Query for columns of each table
    for (const table of tables) {
        try {
            const formData = new FormData();
            formData.append('schema', schema);
            formData.append('table', table);

            const response = await fetch('getColumns.cfm', {
                method: 'POST',
                body: formData
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const columns = await response.json();
            console.log(`Columns received for ${table}:`, columns);

            if (Array.isArray(columns)) {
                columnData[table] = columns;
                // Update the column select dropdowns
                updateColumnSelects(table, columns);
            } else {
                console.error(`Invalid column data received for ${table}:`, columns);
            }
        } catch (error) {
            console.error(`Error loading columns for ${table}:`, error);
        }
    }
    
    return columnData;
}

function updateColumnSelects(table, columns) {
    console.log(`Updating selects for ${table} with columns:`, columns);
    // Update all dropdowns that should contain this table's columns
    document.querySelectorAll('.column-select').forEach(select => {
        const tableSpan = select.previousElementSibling;
        if (tableSpan && tableSpan.textContent === table) {
            select.innerHTML = columns.map(col => 
                `<option value="${table}.${col.COLUMN_NAME}">${col.COLUMN_NAME}</option>`
            ).join('');
        }
    });
}

function showColumnSelector() {
    document.getElementById('columnSelector').style.display = 'block';
    document.getElementById('exportConfig').style.display = 'block';
    loadAvailableColumns();
}

function loadAvailableColumns() {
    // This would make an AJAX call to get all available columns
    console.log('Loading available columns...');
}

// Initialize column sorting
const selectedColumns = document.getElementById('selectedColumns');
if (selectedColumns) {
    new Sortable(selectedColumns, {
        animation: 150,
        ghostClass: 'sortable-ghost'
    });
}

function gatherJoinConfig() {
    const joins = [];
    const joinRows = document.querySelectorAll('.join-row');
    joinRows.forEach((row, index) => {
        const joinType = row.querySelector(`select[name="joinType${index + 1}"]`).value;
        const leftCol = row.querySelector(`select[name="leftColumn${index + 1}"]`).value;
        const rightCol = row.querySelector(`select[name="rightColumn${index + 1}"]`).value;
        joins.push(`${joinType} ON ${leftCol} = ${rightCol}`);
    });
    return joins;
}

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