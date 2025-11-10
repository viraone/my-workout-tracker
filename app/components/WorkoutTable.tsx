import React, { useState } from 'react';
import { WorkoutEntry } from '../../workoutData'; // FIX: Remove the .ts extension
import { FiEdit2, FiTrash2 } from 'react-icons/fi'; // Import the Trash icon (FiTrash2)

interface WorkoutTableProps {
  data: WorkoutEntry[];
  onUpdateSet: (index: number, updatedEntry: WorkoutEntry) => void;
  onDeleteSet: (index: number) => void; // NEW: Handler for deleting a set
}

interface WorkoutRowProps {
  entry: WorkoutEntry;
  index: number;
  isEditing: boolean;
  onEditStart: (index: number) => void;
  onEditSave: (index: number, updatedEntry: WorkoutEntry) => void;
  onEditCancel: () => void;
  onDelete: (index: number) => void; // NEW: Handler for deleting
}

// ----------------------------------------------------------------------
// 1. WORKOUT ROW COMPONENT (Handles Display, Editing, and Deleting)
// ----------------------------------------------------------------------

const WorkoutRow: React.FC<WorkoutRowProps> = ({ 
    entry, 
    index, 
    isEditing, 
    onEditStart, 
    onEditSave, 
    onEditCancel,
    onDelete // Destructure the new delete handler
}) => {
    // Local state to manage the temporary form data during editing
    const [editData, setEditData] = useState(entry);

    const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const { name, value, type } = e.target;
        setEditData(prevData => ({
            ...prevData,
            [name]: type === 'number' ? Number(value) : value,
        } as WorkoutEntry)); 
    };
    
    // Handler for the delete action with a confirmation prompt
    const handleDeleteClick = () => {
        if (window.confirm(`Are you sure you want to delete the set: ${entry.exercise} (${entry.weightLbs} lbs)?`)) {
            onDelete(index);
        }
    };


    if (isEditing) {
        // RENDER EDITING MODE (Inputs instead of plain text)
        return (
            <tr className="bg-yellow-50 border-b">
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
                <td className="p-2"></td> {/* Empty column when editing */}
            </tr>
        );
    }
    
    // RENDER DISPLAY MODE (Default View)
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
            
            {/* Action Column: Edit Icon */}
            <td className="p-3 text-sm text-gray-500">
                <button 
                    onClick={() => onEditStart(index)}
                    className="text-gray-400 hover:text-indigo-600 transition-colors mr-2"
                    aria-label="Edit set"
                >
                    <FiEdit2 size={16} /> 
                </button>
            </td>
            
            {/* NEW Action Column: Delete Icon */}
            <td className="p-3 text-sm text-gray-500">
                <button 
                    onClick={handleDeleteClick}
                    className="text-gray-400 hover:text-red-600 transition-colors"
                    aria-label="Delete set"
                >
                    <FiTrash2 size={16} /> {/* The Trash Icon */}
                </button>
            </td>
        </tr>
    );
};

// ----------------------------------------------------------------------
// 2. MAIN TABLE COMPONENT
// ----------------------------------------------------------------------

const WorkoutTable: React.FC<WorkoutTableProps> = ({ data, onUpdateSet, onDeleteSet }) => {
    // State to track which row (by index) is currently in editing mode
    const [editingIndex, setEditingIndex] = useState<number | null>(null);

    const handleEditStart = (index: number) => {
        setEditingIndex(index);
    };

    const handleEditSave = (index: number, updatedEntry: WorkoutEntry) => {
        onUpdateSet(index, updatedEntry); // Pass update to the parent (page.tsx)
        setEditingIndex(null); // Exit editing mode
    };

    const handleEditCancel = () => {
        setEditingIndex(null); // Exit editing mode
    };

    return (
        <div className="overflow-x-auto shadow-xl rounded-xl">
            <table className="min-w-full divide-y divide-gray-200">
                <thead>
                    <tr className="bg-gray-100">
                        <th className="p-3 text-left text-xs font-bold text-gray-600 uppercase tracking-wider">Date</th>
                        <th className="p-3 text-left text-xs font-bold text-gray-600 uppercase tracking-wider">Exercise</th>
                        <th className="p-3 text-left text-xs font-bold text-gray-600 uppercase tracking-wider">Set</th>
                        <th className="p-3 text-left text-xs font-bold text-gray-600 uppercase tracking-wider">Weight (lbs)</th>
                        <th className="p-3 text-left text-xs font-bold text-gray-600 uppercase tracking-wider">Reps</th>
                        <th className="p-3 text-left text-xs font-bold text-gray-600 uppercase tracking-wider">Muscle Group</th>
                        <th className="p-3 text-left text-xs font-bold text-gray-600 uppercase tracking-wider">Notes</th>
                        <th className="p-3 text-left text-xs font-bold text-gray-600 uppercase tracking-wider">Edit</th> {/* Column for Edit */}
                        <th className="p-3 text-left text-xs font-bold text-gray-600 uppercase tracking-wider">Del</th> {/* NEW Column for Delete */}
                    </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                    {data.map((workout, index) => (
                        <WorkoutRow 
                            key={index} 
                            entry={workout} 
                            index={index}
                            isEditing={editingIndex === index}
                            onEditStart={handleEditStart}
                            onEditSave={handleEditSave}
                            onEditCancel={handleEditCancel}
                            onDelete={onDeleteSet} // Pass the delete handler
                        />
                    ))}
                </tbody>
            </table>
        </div>
    );
};

export default WorkoutTable;