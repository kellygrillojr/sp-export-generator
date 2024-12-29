...existing code remains the same until the style section...

/* Add new CSS inside existing style block */
/* Column selection styles - new addition */
.column-selection {
    display: flex;
    gap: 20px;
    margin-top: 15px;
}
.column-list {
    border: 1px solid ##ccc;
    padding: 10px;
    border-radius: 4px;
    min-height: 200px;
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

...rest of existing code remains the same until loadAvailableColumns function...

async function loadAvailableColumns() {
    const schema = document.querySelector('select[name="selectedSchema"]').value;
    const selectedTables = Array.from(document.querySelector('select[name="selectedTables"]').selectedOptions)
        .map(option => option.value);
    
    const availableColumnsDiv = document.getElementById('availableColumns');
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
        
        let html = '<div class="column-selection">';
        html += '<div class="column-list">';
        allColumns.forEach(col => {
            html += `
                <div class="column-item" draggable="true" 
                     data-table="${col.table}" 
                     data-column="${col.column}" 
                     onclick="addColumnToSelected(this)">
                    ${col.table}.${col.column}
                    <span class="data-type">(${col.dataType})</span>
                </div>`;
        });
        html += '</div></div>';
        
        availableColumnsDiv.innerHTML = html;
        
    } catch (error) {
        console.error('Error loading columns:', error);
        availableColumnsDiv.innerHTML = `<div class="error">Error loading columns: ${error.message}</div>`;
    }
}

...rest of existing code remains the same until just before the closing script tag...

function addColumnToSelected(columnElement) {
    const columnId = `${columnElement.dataset.table}.${columnElement.dataset.column}`;
    if (document.querySelector(`.selected-column[data-column="${columnId}"]`)) {
        return;
    }

    const selectedColumns = document.getElementById('selectedColumns');
    const newColumn = document.createElement('li');
    newColumn.className = 'selected-column';
    newColumn.dataset.column = columnId;
    newColumn.innerHTML = `
        ${columnId}
        <button onclick="removeColumn(this.parentElement)" class="remove-column">×</button>
    `;
    selectedColumns.appendChild(newColumn);
}

function removeColumn(columnElement) {
    columnElement.remove();
}

...rest of existing code remains the same...