import React, { useState, useEffect } from 'react'; // <-- IMPORTANT: useEffect added here
import { WorkoutEntry } from '../../workoutData';
import { FiEdit2, FiTrash2, FiChevronUp, FiChevronDown } from 'react-icons/fi';

// Define types for sorting state
type SortKey = keyof WorkoutEntry | null;
type SortDirection = 'asc' | 'desc';

// --- UPDATED PROP INTERFACES (These look correct based on your previous code) ---
interface WorkoutTableProps {
  data: WorkoutEntry[];
  onUpdateSet: (index: number, updatedEntry: WorkoutEntry) => void;
  onDeleteSet: (index: number) => void; 
  onSort: (key: SortKey) => void; 
  sortBy: SortKey; 
  sortDirection: SortDirection;
}

interface WorkoutRowProps {
  entry: WorkoutEntry;
  uniqueId: string; 
  index: number; 
  isEditing: boolean;
  onEditStart: (uniqueId: string, index: number) => void; 
  onEditSave: (index: number, updatedEntry: WorkoutEntry) => void;
  onEditCancel: () => void;
  onDelete: (index: number) => void; 
}

// ----------------------------------------------------------------------
// 1. WORKOUT ROW COMPONENT (CRITICAL FIX ADDED HERE)
// ----------------------------------------------------------------------

const WorkoutRow: React.FC<WorkoutRowProps> = ({ 
    entry, 
    index, 
    uniqueId, 
    isEditing, 
    onEditStart, 
    onEditSave, 
    onEditCancel,
    onDelete 
}) => {
    const [editData, setEditData] = useState(entry);

    // CRITICAL FIX: Use useEffect to reset the edit form state when the row starts editing.
    // This ensures the inputs (like date, weight, etc.) are always populated with the 
    // correct 'entry' data for this specific row, regardless of sorting/caching issues.
    useEffect(() => {
        if (isEditing) {
            setEditData(entry); // Sync local state with current props
        }
    }, [isEditing, entry]); // Re-run whenever editing status or entry data changes


    const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const { name, value, type } = e.target;
        setEditData(prevData => ({
            ...prevData,
            [name]: type === 'number' ? Number(value) : value,
        } as WorkoutEntry)); 
    };
    
    const handleDeleteClick = () => {
        if (window.confirm(`Are you sure you want to delete the set: ${entry.exercise} (${entry.weightLbs} lbs)?`)) {
            onDelete(index);
        }
    };

    if (isEditing) {
        return (
            <tr className="bg-yellow-50 border-b">
                {/* Inputs are now reliably populated by the current editData state */}
                <td className="p-2"><input type="text" name="date" value={editData.date} onChange={handleChange} className="w-full text-sm p-1 border rounded" /></td>
                <td className="p-2"><input type="text" name="exercise" value={editData.exercise} onChange={handleChange} className="w-full text-sm p-1 border rounded" /></td>
                <td className="p-2"><input type="number" name="set" value={editData.set} onChange={handleChange} className="w-full text-sm p-1 border rounded" /></td>
                <td className="p-2"><input type="number" name="weightLbs" value={editData.weightLbs} onChange={handleChange} className="w-full text-sm p-1 border rounded" /></td>
                <td className="p-2"><input type="number" name="reps" value={editData.reps} onChange={handleChange} className="w-full text-sm p-1 border rounded" /></td>
                <td className="p-2"><input type="text" name="muscleGroup" value={editData.muscleGroup} onChange={handleChange} className="w-full text-sm p-1 border rounded" /></td>
                <td className="p-2"><input type="text" name="notes" value={editData.notes} onChange={handleChange} className="w-full text-sm p-1 border rounded" /></td>
                <td className="p-2 flex space-x-2">
                    <button onClick={() => onEditSave(index, editData)} className="text-white bg-green-500 hover:bg-green-600 px-2 py-1 rounded text-xs">Save</button>
                    <button onClick={onEditCancel} className="text-white bg-red-500 hover:bg-red-600 px-2 py-1 rounded text-xs">Cancel</button>
                </td>
                <td className="p-2"></td>
            </tr>
        );
    }
    
    return (
        <tr className="border-b hover:bg-gray-50 transition-colors duration-150">
            <td className="p-3 text-sm font-medium text-gray-900">{entry.date}</td>
            <td className="p-3 text-sm font-bold text-indigo-600">{entry.exercise}</td>
            <td className="p-3 text-sm text-gray-500">{entry.set || 1}</td>
            <td className="p-3 text-sm text-gray-900">{entry.weightLbs} lbs</td>
            <td className="p-3 text-sm text-gray-500">{entry.reps}</td>
            <td className="p-3 text-sm text-gray-600">
                <span className="inline-flex items-center rounded-full bg-blue-100 px-3 py-0.5 text-xs font-medium text-blue-800">
                    {entry.muscleGroup}
                </span>
            </td>
            <td className="p-3 text-sm text-gray-500 italic">{entry.notes || '-'}</td>
            
            <td className="p-3 text-sm text-gray-500">
                <button 
                    onClick={() => onEditStart(uniqueId, index)}
                    className="text-gray-400 hover:text-indigo-600 transition-colors mr-2"
                    aria-label="Edit set"
                >
                    <FiEdit2 size={16} /> 
                </button>
            </td>
            
            <td className="p-3 text-sm text-gray-500">
                <button 
                    onClick={handleDeleteClick}
                    className="text-gray-400 hover:text-red-600 transition-colors"
                    aria-label="Delete set"
                >
                    <FiTrash2 size={16} /> 
                </button>
            </td>
        </tr>
    );
};

// ----------------------------------------------------------------------
// 2. SORTABLE HEADER COMPONENT (Omitted for brevity, code is correct)
// ----------------------------------------------------------------------

const SortableHeader: React.FC<{ 
    label: string, 
    sortKey: SortKey, 
    currentSortBy: SortKey, 
    currentDirection: SortDirection, 
    onSort: (key: SortKey) => void 
}> = ({ label, sortKey, currentSortBy, currentDirection, onSort }) => {
    
    const isSorted = currentSortBy === sortKey;
    
    // Function to render the sort arrow icon
    const renderSortIcon = () => {
        if (!isSorted) {
            return <FiChevronUp size={14} className="opacity-0 group-hover:opacity-50 transition-opacity" />;
        }
        if (currentDirection === 'asc') {
            return <FiChevronUp size={14} className="text-indigo-600" />;
        }
        return <FiChevronDown size={14} className="text-indigo-600" />;
    };

    return (
        <th 
            className="p-3 text-left text-xs font-bold text-gray-600 uppercase tracking-wider cursor-pointer hover:bg-gray-200 transition-colors"
            onClick={() => onSort(sortKey)}
        >
            <div className="flex items-center group">
                <span className="mr-1">{label}</span>
                {renderSortIcon()}
            </div>
        </th>
    );
};


// ----------------------------------------------------------------------
// 3. MAIN TABLE COMPONENT (Omitted for brevity, code is correct)
// ----------------------------------------------------------------------

const WorkoutTable: React.FC<WorkoutTableProps> = ({ 
    data, 
    onUpdateSet, 
    onDeleteSet,
    onSort, 
    sortBy, 
    sortDirection
}) => {
    // FIX 2: Change editingIndex state type to string (to match uniqueId)
    const [editingIndex, setEditingIndex] = useState<string | null>(null);
    const [editingData, setEditingData] = useState<WorkoutEntry | null>(null);


    const handleEditStart = (id: string, index: number) => {
        setEditingIndex(id);
        // FIX 3: Set the editing data right away to prevent showing old data
        setEditingData(data[index]);
    };

    const handleEditSave = (index: number, updatedEntry: WorkoutEntry) => {
        onUpdateSet(index, updatedEntry); 
        setEditingIndex(null); 
    };

    const handleEditCancel = () => {
        setEditingIndex(null); 
    };

    return (
        <div className="overflow-x-auto shadow-xl rounded-xl">
            <table className="min-w-full divide-y divide-gray-200">
                <thead>
                    <tr className="bg-gray-100">
                        {/* Headers (omitted for brevity, assume they are correct) */}
                        <SortableHeader label="Date" sortKey="date" {...{ onSort, currentSortBy: sortBy, currentDirection: sortDirection }} />
                        <SortableHeader label="Exercise" sortKey="exercise" {...{ onSort, currentSortBy: sortBy, currentDirection: sortDirection }} />
                        <SortableHeader label="Set" sortKey="set" {...{ onSort, currentSortBy: sortBy, currentDirection: sortDirection }} />
                        <SortableHeader label="Weight (lbs)" sortKey="weightLbs" {...{ onSort, currentSortBy: sortBy, currentDirection: sortDirection }} />
                        <SortableHeader label="Reps" sortKey="reps" {...{ onSort, currentSortBy: sortBy, currentDirection: sortDirection }} />
                        <SortableHeader label="Muscle Group" sortKey="muscleGroup" {...{ onSort, currentSortBy: sortBy, currentDirection: sortDirection }} />
                        
                        {/* Non-Sortable Headers */}
                        <th className="p-3 text-left text-xs font-bold text-gray-600 uppercase tracking-wider">Notes</th>
                        <th className="p-3 text-left text-xs font-bold text-gray-600 uppercase tracking-wider">Edit</th> 
                        <th className="p-3 text-left text-xs font-bold text-gray-600 uppercase tracking-wider">Del</th> 
                    </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                    {data.map((workout, index) => {
                        // Create a stable unique ID based on the data fields
                        const uniqueId = `${workout.date}-${workout.exercise}-${workout.set}-${workout.weightLbs}`;
                        
                        return (
                            <WorkoutRow 
                                key={uniqueId} 
                                entry={workout} 
                                index={index} 
                                uniqueId={uniqueId} // Pass uniqueId
                                isEditing={editingIndex === uniqueId} // Check uniqueId for editing
                                onEditStart={handleEditStart} 
                                onEditSave={handleEditSave} 
                                onEditCancel={handleEditCancel} 
                                onDelete={onDeleteSet} 
                            />
                        );
                    })}
                </tbody>
            </table>
        </div>
    );
};

export default WorkoutTable;