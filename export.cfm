<cfinclude template="../includes/header.cfm">
<!--- export.cfm --->
<cfoutput>
<!--- Previous HTML remains the same until the join configuration section --->

        <!--- Step 3: Join Configuration --->
        <div class="step" id="joinBuilder" style="display: none;">
            <h2>Step 3: Configure Joins</h2>
            <div id="joinConfig">
                <!-- Join configuration will be populated dynamically -->
            </div>
            <button type="button" onclick="showColumnSelector()">Next: Select Columns</button>
        </div>

<!--- Rest of the HTML remains the same --->

<script>
// Previous JavaScript functions remain the same until buildJoinInterface

function buildJoinInterface(tables) {
    console.log('Building join interface for tables:', tables);
    const joinConfig = document.getElementById('joinConfig');
    joinConfig.innerHTML = '';

    if (tables.length === 1) {
        joinConfig.innerHTML = '<p>No joins needed for single table.</p>';
        return;
    }

    // First, let's load all columns for the selected tables
    loadAllTableColumns(tables).then(columnData => {
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
                            ${generateColumnOptions(columnData[baseTable] || [])}
                        </select>
                        =
                        <span class="table-name">${joinTable}</span>
                        <select name="rightColumn${i}" class="column-select">
                            ${generateColumnOptions(columnData[joinTable] || [])}
                        </select>
                    </div>
                </div>
            `;
        }
        html += '</div>';
        joinConfig.innerHTML = html;
    });
}

async function loadAllTableColumns(tables) {
    const schema = document.querySelector('select[name="selectedSchema"]').value;
    const columnData = {};
    
    // Query for columns of each table
    for (const table of tables) {
        try {
            const response = await fetch('getColumns.cfm', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: `schema=${encodeURIComponent(schema)}&table=${encodeURIComponent(table)}`
            });
            const columns = await response.json();
            columnData[table] = columns;
        } catch (error) {
            console.error(`Error loading columns for ${table}:`, error);
            columnData[table] = [];
        }
    }
    
    return columnData;
}

function generateColumnOptions(columns) {
    return columns.map(column => 
        `<option value="${column.COLUMN_NAME}">${column.COLUMN_NAME}</option>`
    ).join('');
}

// Rest of the JavaScript remains the same
</script>
</cfoutput>

<!--- Add a new file for getting columns: getColumns.cfm --->
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
</cfif>