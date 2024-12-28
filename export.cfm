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
        /* Column selection styles */
        .column-selection {
            display: flex;
            gap: 20px;
        }
        .available-columns, .selected-columns {
            flex: 1;
            padding: 15px;
            border: 1px solid ##ccc;
            border-radius: 4px;
        }
        .column-item {
            padding: 8px;
            margin: 4px 0;
            background: ##f5f5f5;
            border: 1px solid ##ddd;
            border-radius: 4px;
            cursor: pointer;
        }
        .column-item:hover {
            background: ##e5e5e5;
        }
        .data-type {
            color: ##666;
            font-size: 0.9em;
            margin-left: 5px;
        }
        .selected-column {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 8px;
            margin: 4px 0;
            background: ##f5f5f5;
            border: 1px solid ##ddd;
            border-radius: 4px;
        }
        .remove-column {
            border: none;
            background: none;
            color: ##999;
            cursor: pointer;
            font-size: 1.2em;
            padding: 0 5px;
        }
        .remove-column:hover {
            color: ##666;
        }
    </style>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/Sortable/1.14.0/Sortable.min.js"></script>
</head>
<body>
<!-- Previous HTML remains the same until the column selector section -->

        <!--- Step 4: Column Selection --->
        <div class="step" id="columnSelector" style="display: none;">
            <h2>Step 4: Select and Order Columns</h2>
            <div class="column-selection">
                <div id="availableColumns" class="available-columns">
                    <h3>Available Columns</h3>
                    <!-- Available columns will be loaded here -->
                </div>
                <div class="selected-columns-container">
                    <h3>Selected Columns</h3>
                    <ul id="selectedColumns" class="selected-columns">
                        <!-- Selected columns will be here -->
                    </ul>
                </div>
            </div>
        </div>

<!-- Previous HTML remains the same -->

<script>
// Previous JavaScript remains the same until loadAvailableColumns

async function loadAvailableColumns() {
    const schema = document.querySelector('select[name="selectedSchema"]').value;
    const selectedTables = Array.from(document.querySelector('select[name="selectedTables"]').selectedOptions)
        .map(option => option.value);
    
    const availableColumnsDiv = document.getElementById('availableColumns');
    const selectedColumnsDiv = document.getElementById('selectedColumns');
    
    availableColumnsDiv.innerHTML = '<div class="loading">Loading columns...</div>';
    
    try {
        const allColumns = [];
        
        for (const table of selectedTables) {
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
            if (Array.isArray(columns)) {
                columns.forEach(col => {
                    allColumns.push({
                        table: table,
                        column: col.COLUMN_NAME,
                        dataType: col.DATA_TYPE
                    });
                });
            }
        }
        
        // Create the column selection interface
        let html = '<h3>Available Columns</h3>';
        html += '<div class="column-list">';
        allColumns.forEach(col => {
            html += `
                <div class="column-item" draggable="true" 
                     data-table="${col.table}" 
                     data-column="${col.column}">
                    ${col.table}.${col.column}
                    <span class="data-type">(${col.dataType})</span>
                </div>`;
        });
        html += '</div>';
        
        availableColumnsDiv.innerHTML = html;
        
        // Initialize drag and drop
        initializeDragAndDrop();
        
    } catch (error) {
        console.error('Error loading columns:', error);
        availableColumnsDiv.innerHTML = `<div class="error">Error loading columns: ${error.message}</div>`;
    }
}

function initializeDragAndDrop() {
    const columnItems = document.querySelectorAll('.column-item');
    const selectedColumns = document.getElementById('selectedColumns');

    columnItems.forEach(item => {
        item.addEventListener('dragstart', handleDragStart);
        item.addEventListener('click', handleColumnClick);
    });

    selectedColumns.addEventListener('dragover', handleDragOver);
    selectedColumns.addEventListener('drop', handleDrop);
}

function handleDragStart(e) {
    e.dataTransfer.setData('text/plain', JSON.stringify({
        table: this.dataset.table,
        column: this.dataset.column
    }));
}

function handleDragOver(e) {
    e.preventDefault();
}

function handleDrop(e) {
    e.preventDefault();
    const data = JSON.parse(e.dataTransfer.getData('text/plain'));
    addColumnToSelected(data);
}

function handleColumnClick(e) {
    const columnData = {
        table: this.dataset.table,
        column: this.dataset.column
    };
    addColumnToSelected(columnData);
}

function addColumnToSelected(columnData) {
    const selectedColumns = document.getElementById('selectedColumns');
    const newColumn = document.createElement('li');
    newColumn.className = 'selected-column';
    newColumn.dataset.column = `${columnData.table}.${columnData.column}`;
    newColumn.innerHTML = `
        ${columnData.table}.${columnData.column}
        <button onclick="removeColumn(this.parentElement)" class="remove-column">×</button>
    `;
    selectedColumns.appendChild(newColumn);
}

function removeColumn(columnElement) {
    columnElement.remove();
}

// Initialize Sortable for the selected columns
let sortable = new Sortable(document.getElementById('selectedColumns'), {
    animation: 150,
    ghostClass: 'sortable-ghost'
});

// Previous JavaScript remains the same
</script>
</cfoutput>
<cfinclude template="../includes/footer.cfm">