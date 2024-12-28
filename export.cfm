<cfinclude template="../includes/header.cfm">
<!--- Previous code remains the same until loadAllTableColumns function --->

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

<!--- Rest of the code remains the same --->